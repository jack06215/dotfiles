#!/usr/bin/env python3
import json
import subprocess
import sys
import textwrap


def build_query(org, repo, author, after, until):
    return textwrap.dedent("""
        {
          search(
            query: "repo:%s/%s author:%s created:%s..%s type:pr",
            type: ISSUE,
            first: 100
          ) {
            nodes {
              ... on PullRequest {
                number
                body
                reviews(first: 100) {
                  nodes {
                    author { login }
                    body
                    submittedAt
                    state
                  }
                }
              }
            }
          }
        }
    """).strip() % (org, repo, author, after, until)


def main():
    if len(sys.argv) != 6:
        print("Usage: pr-reviews.py <org> <repo> <author> <after> <until>")
        sys.exit(1)

    org = sys.argv[1]
    repo = sys.argv[2]
    author = sys.argv[3]
    after = sys.argv[4]
    until = sys.argv[5]

    result = subprocess.run(
        [
            "gh",
            "api",
            "graphql",
            "-f",
            "query=%s" % build_query(org, repo, author, after, until),
        ],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        print("Error:", result.stderr, file=sys.stderr)
        sys.exit(1)

    data = json.loads(result.stdout)
    nodes = data["data"]["search"]["nodes"]

    output = []
    for node in nodes:
        reviews = [
            {
                "author": r["author"]["login"],
                "body": r["body"],
                "submitted_at": r["submittedAt"],
                "state": r["state"],
            }
            for r in node["reviews"]["nodes"]
        ]

        state_counts = {}
        for r in reviews:
            state_counts[r["state"]] = state_counts.get(r["state"], 0) + 1
        reviews_count = [{"state": s, "count": c} for s, c in state_counts.items()]

        output.append(
            {
                "pr_number": node["number"],
                "body": node["body"],
                "reviews": reviews,
                "reviews_count": reviews_count,
            }
        )

    print(json.dumps(output, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
