-- Japanese input: the half a completion menu cannot reach.
--
-- blink-cmp-im (lua/plugins/blink/config.lua) completes whole words from a
-- romaji key, which covers nouns, compounds and proper nouns but stops dead at
-- anything inflected. SKK keeps verb and adjective stems in its okuri-ari
-- half, keyed like `わかr /分/`, and turning that into 分かりました is live
-- conversion, not a lookup -- there is no table of conjugated forms to
-- generate, and the jisyo cannot even tell godan from ichidan (分かる and
-- 食べる are both `…r`), so synthesising them would be guesswork.
--
-- SKK is the thing that does this properly, and skkeleton is SKK for nvim.
-- denops is already loaded for kensaku, so this costs one plugin and no new
-- runtime: kensaku matches Japanese from romaji, skkeleton writes it.

local data_home = vim.env.XDG_DATA_HOME or vim.fn.expand("~/.local/share")
local ja_dir = data_home .. "/dict-ja"

-- Written by run_onchange_after_generate-jisyo.sh.tmpl, same run that builds
-- the romaji table. UTF-8, so globalDictionaries needs no encoding argument.
local global_jisyo = ja_dir .. "/SKK-JISYO.utf8"

-- Words learned while converting. In the config tree rather than skkeleton's
-- default of ~/.skkeleton for the same reason 'spellfile' is (config/general.lua):
-- this is hand-earned personal data -- every conversion picked here reorders
-- the candidate list -- so chezmoi should carry it between machines instead of
-- leaving it to be relearned from scratch on each one.
--
-- Same caveat as the spell file, too: skkeleton writes to the chezmoi *target*,
-- so new words need `chezmoi add ~/.config/nvim/skk/user-jisyo` or the next
-- apply reverts them. See README.md.
local user_jisyo = vim.fn.stdpath("config") .. "/skk/user-jisyo"

return {
  "vim-skk/skkeleton",

  -- The same denops kensaku, flash and fuzzy-motion already pull in; lazy
  -- dedupes it. kensaku loads it eagerly, so it is up well before the first
  -- InsertEnter and skkeleton never races its startup.
  dependencies = { "vim-denops/denops.vim" },

  -- Deliberately not lazy-loaded, for the same reason kensaku is not, and
  -- then some: denops discovers `denops/*/main.ts` by scanning the
  -- runtimepath when it starts. A plugin added to the runtimepath afterwards
  -- -- which is exactly what lazy-loading on InsertEnter does -- is never
  -- registered, and `skkeleton#handle('enable')` then waits forever on a
  -- plugin denops does not know about. That presents as the cursor freezing
  -- on the first <C-j>, with no error.

  config = function()
    vim.fn.mkdir(vim.fn.fnamemodify(user_jisyo, ":h"), "p")

    -- config() has to run against a live denops instance; this event is the
    -- documented hook for exactly that.
    vim.api.nvim_create_autocmd("User", {
      pattern = "skkeleton-initialize-pre",
      group = vim.api.nvim_create_augroup("SkkeletonConfigAUG", { clear = true }),
      callback = function()
        vim.fn["skkeleton#config"]({
          globalDictionaries = { global_jisyo },
          userDictionary = user_jisyo,
          -- <CR> during conversion confirms the candidate instead of also
          -- breaking the line -- without this, accepting 分かり lands you on
          -- the next line mid-sentence.
          eggLikeNewline = true,
          -- Remember okuri-ari conversions, so the readings actually used
          -- drift to the front of the candidate list.
          registerConvertResult = true,
        })
      end,
    })

    require("plugins.skkeleton.keymaps").create_keymaps()

    -- blink and skkeleton both want the keys while composing, and blink wins
    -- ties: leaving it on means <CR> accepts a completion instead of the
    -- candidate under ▼. `vim.b.completion` is blink's own per-buffer switch
    -- (blink/cmp/config/init.lua), and clearing it back to nil restores the
    -- default rather than pinning completion on.
    local aug = vim.api.nvim_create_augroup("SkkeletonBlinkAUG", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      pattern = "skkeleton-enable-pre",
      group = aug,
      callback = function()
        vim.b.completion = false
      end,
    })
    vim.api.nvim_create_autocmd("User", {
      pattern = "skkeleton-disable-post",
      group = aug,
      callback = function()
        vim.b.completion = nil
      end,
    })
  end,
}
