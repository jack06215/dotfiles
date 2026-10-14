# Copilot status line: AI credit ledger

The Copilot status line (`dot_config/private_copilot/executable_statusline_command.sh`)
shows this month's AI credit (AIC) spend against a monthly allowance:

```
5.00 AIC │ 12m │ month 305/1900 16%
```

Copilot can't provide that number itself. The seat is on token-based billing,
and its quota snapshots report every quota as `unlimited` with an entitlement
of 0. The JSON Copilot pipes to the status line command only carries the
running session's total, in `ai_used.total_nano_aiu`. So the script keeps its
own ledger: every refresh records the session's total, and the monthly figure
is the sum over this month's sessions.

The allowance is `AIC_BUDGET` at the top of the script.

## Where it lives

```
${XDG_STATE_HOME:-$HOME/.local/state}/copilot/aic.db
```

The script creates the directory and table on first run. It's machine-local
state, so chezmoi doesn't manage it.

## Schema

```sql
CREATE TABLE IF NOT EXISTS aic (
  month TEXT NOT NULL,
  session_id TEXT NOT NULL,
  banked_nano INTEGER NOT NULL DEFAULT 0,
  session_nano INTEGER NOT NULL,
  PRIMARY KEY (month, session_id)
);
```

| Column         | Meaning                                                                                  |
| -------------- | ---------------------------------------------------------------------------------------- |
| `month`        | Billing month as `YYYY-MM`, in UTC (`strftime('%Y-%m', 'now')`).                         |
| `session_id`   | Copilot's `session_id` from the status line payload.                                     |
| `banked_nano`  | Credits the session had used before `/clear` or `/new` reset its count.                  |
| `session_nano` | The session's count as of its latest refresh: `ai_used.total_nano_aiu`.                  |

There's one row per session per month. A session's spend for the month is
`banked_nano + session_nano`.

**Units.** Every amount is stored in nano-AIU, the unit Copilot reports in:
1 AIC = 1,000,000,000 nano-AIU. SQLite sums these as 64-bit integers, so the
total is exact. The script only converts to AIC for display.

**Month.** The month is computed in UTC because Copilot's quota resets on the
1st at 00:00 UTC (`quota_reset_date_utc`), which is 09:00 JST. Older months
stay in the table but don't count toward the current month.

## How a refresh writes

Each status line refresh runs one upsert:

```sql
INSERT INTO aic (month, session_id, session_nano)
  VALUES (strftime('%Y-%m', 'now'), '<session_id>', <total_nano_aiu>)
  ON CONFLICT (month, session_id) DO UPDATE SET
    banked_nano = banked_nano + iif(excluded.session_nano < session_nano, session_nano, 0),
    session_nano = excluded.session_nano
  WHERE excluded.session_nano != session_nano;
```

- **New session:** a row is inserted with `banked_nano = 0`.
- **The count went up:** `session_nano` is replaced with the new total.
- **The count went down:** `/clear` and `/new` reset Copilot's count. Before
  `session_nano` takes the smaller value, the old one is added to
  `banked_nano`, so the spend isn't lost.
- **No change:** the `WHERE` skips the update, so refreshes that don't change
  anything don't rewrite the row.

Here's one session's row over time (amounts in AIC; the table stores nano-AIU):

| Refresh      | Copilot reports | `banked_nano` | `session_nano` | Counts toward the month |
| ------------ | --------------: | ------------: | -------------: | ----------------------: |
| first turn   |            0.42 |             0 |           0.42 |                    0.42 |
| later turn   |            5.00 |             0 |           5.00 |                    5.00 |
| after /clear |            0.10 |          5.00 |           0.10 |                    5.10 |

Then the month total is read in the same `sqlite3` call:

```sql
SELECT coalesce(sum(banked_nano + session_nano), 0) FROM aic
WHERE month = strftime('%Y-%m', 'now');
```

### Concurrency

Several Copilot sessions can refresh at the same moment, for example tmux panes
started by agent-hatch. SQLite's locking makes those writes take turns, and
`.timeout 2000` makes a writer wait up to 2s for the lock instead of failing.
In testing, 30 sessions writing at once all kept their rows.

### Input checks

The session id and count are inserted into the SQL text directly rather than
bound as parameters. So the script only writes when `session_id` matches
`^[A-Za-z0-9_-]+$` and the count matches `^[0-9]+$`. If either doesn't match,
the refresh skips the write but still reads the month total.

## Useful queries

```sh
db=~/.local/state/copilot/aic.db

# This month's total, in AIC
sqlite3 "$db" "SELECT sum(banked_nano + session_nano) / 1e9 FROM aic
  WHERE month = strftime('%Y-%m', 'now')"

# Per-session breakdown for this month, largest first
sqlite3 -header -column "$db" "SELECT session_id,
    round((banked_nano + session_nano) / 1e9, 2) AS aic
  FROM aic WHERE month = strftime('%Y-%m', 'now') ORDER BY aic DESC"

# Totals by month
sqlite3 -header -column "$db" "SELECT month,
    round(sum(banked_nano + session_nano) / 1e9, 2) AS aic
  FROM aic GROUP BY month ORDER BY month"

# Add spend the ledger didn't see (here 400 AIC), e.g. from before it existed
sqlite3 "$db" "INSERT INTO aic VALUES (strftime('%Y-%m', 'now'), 'manual', 0, 400000000000)"

# Delete months older than a year
sqlite3 "$db" "DELETE FROM aic WHERE month < strftime('%Y-%m', 'now', '-12 months')"
```

The `manual` row is just a placeholder session id. Running the insert again in
the same month fails on the primary key, so use `UPDATE` to change the amount.

## Limits

- **It only counts the Copilot CLI on this machine.** Copilot Chat in VS Code,
  github.com and other machines spend from the same monthly credits, but they
  never run this script. Add a `manual` row to account for them.
- **The month boundary isn't exact.** A session that's running across the
  reset (the 1st, 00:00 UTC) starts a new row with its full running total, so
  its spend from the old month counts toward the new one too.
- **Sessions that spend nothing still get a row** with zero credits. They
  don't change the total.
