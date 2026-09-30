local M = {}

-- Keymaps for vscode-neovim (vim.g.vscode). config/keymaps.lua applies these
-- instead of the plugin keymaps.
--
-- Inside VS Code the LazyVim vscode extra (lazyvim/plugins/extras/vscode.lua)
-- loads only a whitelist of plugins plus specs marked `vscode = true`, so
-- telescope, snacks' pickers, neogit, gitsigns, trouble, neotest and lspsaga
-- are not there to call. Each mapping keeps the lhs this config uses in nvim
-- and swaps the rhs for the VS Code command that does the same job.
--
-- Left alone because they already work in VS Code: motions and text objects,
-- flash (s/S), surround (ys/cs/ds), :sort and <leader>so/sO/SD, <leader>ul and
-- <leader>uL (vscode-neovim syncs 'relativenumber' to the editor), <leader>ur,
-- <leader>-/|/wd (LazyVim remaps them onto vscode-neovim's own <C-w> maps), and
-- vscode-neovim's defaults: gd, K, gc/gcc, =, gt/gT, <C-o>/<C-i>, <C-w>*.
--
-- Keys with no VS Code counterpart are unmapped at the bottom rather than left
-- pointing at a snacks float nobody can see.
--
-- Command IDs are checked against VS Code 1.139 and the extensions listed in
-- .chezmoidata/vscode.toml.

local vscode = require("vscode")
local util = require("utils.vscode")

---rhs running one VS Code command. A table `args` reaches the command as its
---single argument (vscode.action wraps any table that is not a list).
---@param name string
---@param args? table
---@return fun()
local function action(name, args)
  return function()
    vscode.action(name, args and { args = args } or nil)
  end
end

---rhs running several VS Code commands in order.
---@param names string[]
---@return fun()
local function actions(names)
  return action("runCommands", { commands = names })
end

---@param mode string|string[]
---@param lhs string
---@param rhs string|fun()
---@param desc string
---@param opts? vim.keymap.set.Opts
local function map(mode, lhs, rhs, desc, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { desc = desc, silent = true }, opts or {}))
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Stand-ins for pickers and popups                                     │
-- ╰──────────────────────────────────────────────────────────────────────╯

---which-key cannot draw in VS Code, so list the leader maps in a quick pick
---(vscode-neovim turns vim.ui.select into one) and run the chosen one.
local function pick_leader_keymap()
  local leader = vim.g.mapleader or "\\"
  local seen, items = {}, {}
  for _, km in ipairs(vim.list_extend(vim.api.nvim_buf_get_keymap(0, "n"), vim.api.nvim_get_keymap("n"))) do
    -- buffer-local maps come first and shadow the global ones
    if km.desc and not seen[km.lhs] and vim.startswith(km.lhs, leader) then
      seen[km.lhs] = true
      table.insert(items, km)
    end
  end
  table.sort(items, function(a, b)
    return a.lhs < b.lhs
  end)

  vim.ui.select(items, {
    prompt = "Leader keymaps",
    format_item = function(km)
      return ("<leader>%-8s %s"):format(km.lhs:sub(#leader + 1), km.desc)
    end,
  }, function(km)
    if km then
      vim.api.nvim_feedkeys(vim.keycode(km.lhs), "m", false)
    end
  end)
end

local ordinals = { "First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth" }

---nvim-window-picker over VS Code's editor groups. Same filter rules: the
---current group is left out, and a single candidate is focused without asking.
local function pick_window()
  local groups = vscode.eval([[
    return vscode.window.tabGroups.all
      .filter((g) => !g.isActive)
      .map((g) => ({ column: g.viewColumn, label: g.activeTab ? g.activeTab.label : "(empty)" }));
  ]]) or {}
  local function focus(group)
    if ordinals[group.column] then
      vscode.action("workbench.action.focus" .. ordinals[group.column] .. "EditorGroup")
    end
  end

  if #groups == 1 then
    return focus(groups[1])
  end
  vim.ui.select(groups, {
    prompt = "Pick window",
    format_item = function(group)
      return ("%d  %s"):format(group.column, group.label)
    end,
  }, function(group)
    if group then
      focus(group)
    end
  end)
end

---VS Code has pin and unpin, but no toggle.
local function toggle_pin()
  local pinned = vscode.eval([[
    const tab = vscode.window.tabGroups.activeTabGroup.activeTab;
    return tab ? tab.isPinned : false;
  ]])
  vscode.action(pinned and "workbench.action.unpinEditor" or "workbench.action.pinEditor")
end

local function close_unpinned()
  vscode.eval_async([[
    const tabs = vscode.window.tabGroups.all.flatMap((g) => g.tabs).filter((t) => !t.isPinned);
    await vscode.window.tabGroups.close(tabs);
  ]])
end

local function confirm_close_all()
  vim.ui.select({ "Yes", "No" }, { prompt = "[WARN] Delete ALL buffers?" }, function(choice)
    if choice == "Yes" then
      vscode.action("workbench.action.closeAllEditors")
    end
  end)
end

---Snacks.lazygit's float, as a terminal in the editor area. lazygit is the
---terminal's process, so the tab closes itself when lazygit quits.
local function lazygit()
  vscode.eval_async([[
    const term = vscode.window.createTerminal({
      name: "lazygit",
      shellPath: "lazygit",
      location: vscode.TerminalLocation.Editor,
    });
    term.show();
  ]])
end

local function format()
  local visual = vim.fn.mode():find("[vV\22]") ~= nil
  vscode.action(visual and "editor.action.formatSelection" or "editor.action.formatDocument")
end

---grug-far opened with the current file's extension as the files filter.
local function search_and_replace()
  local ext = vim.fn.expand("%:e")
  -- A `replace` string is what opens the search view in replace mode;
  -- workbench.action.replaceInFiles itself ignores arguments.
  vscode.action("workbench.action.findInFiles", {
    args = { replace = "", filesToInclude = ext ~= "" and ("*." .. ext) or "" },
  })
end

local function grep_word()
  -- expand() throws E348 off a word; the search view then opens on its last query
  local ok, word = pcall(vim.fn.expand, "<cword>")
  vscode.action("workbench.action.findInFiles", {
    args = ok and { query = word, matchWholeWord = true, triggerSearch = true } or nil,
  })
end

---hlslens' exportLastSearchToQuickfix: VS Code's search view is the quickfix
---list here. Only the regex dialect `*`, `#` and plain `/` produce is carried
---over (word boundaries, a leading \V or \c); anything fancier is passed as-is.
local function search_to_quickfix()
  local pattern = vim.fn.getreg("/")
  if pattern == "" then
    return
  end
  local query = pattern:gsub("\\[<>]", "\\b"):gsub("^\\V", ""):gsub("\\[cC]", "")
  vscode.action("workbench.action.findInFiles", {
    args = { query = query, isRegex = true, triggerSearch = true },
  })
end

---Comment.nvim's gcb (`yyPgccj`) done with VS Code commands: the nvim version
---races vscode-neovim's asynchronous gcc against the `j` after it.
local function comment_backup()
  vscode.call("editor.action.copyLinesUpAction")
  vscode.call("editor.action.commentLine")
  vscode.call("cursorDown")
end

---LazyVim's gco/gcO, likewise: they chain `normal gcc` into more edits.
---@param command "editor.action.insertLineAfter"|"editor.action.insertLineBefore"
local function comment_line(command)
  return function()
    vscode.with_insert(function()
      vscode.action(command, {
        callback = function()
          vscode.action("editor.action.commentLine")
        end,
      })
    end)
  end
end

---Snacks.toggle.diagnostics hides everything: squiggles and the inline text.
local function toggle_diagnostics()
  local on = vscode.get_config("editor.renderValidationDecorations") ~= "off"
  vscode.update_config(
    { "editor.renderValidationDecorations", "errorLens.enabled" },
    { on and "off" or "editable", not on },
    "global"
  )
  util.status("Diagnostics: " .. (on and "off" or "on"), 2000)
end

---The buffer-local autoformat toggle, as the nearest thing VS Code has: a
---per-language editor.formatOnSave.
local function toggle_format_language()
  local result = vscode.eval([[
    const editor = vscode.window.activeTextEditor;
    if (!editor) return null;
    const languageId = editor.document.languageId;
    const config = vscode.workspace.getConfiguration("editor", { languageId });
    const value = !config.get("formatOnSave");
    await config.update("formatOnSave", value, vscode.ConfigurationTarget.Global, true);
    return `${languageId}: ${value}`;
  ]])
  if result and result ~= vim.NIL then
    util.status("Format on save, " .. result, 2000)
  end
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Keymaps                                                              │
-- ╰──────────────────────────────────────────────────────────────────────╯

M.create_keymaps = function()
  -- Top level
  map("n", "<leader>,", action("workbench.action.showAllEditorsByMostRecentlyUsed"), "Buffers")
  map("n", "<leader>/", action("workbench.action.findInFiles"), "Grep")
  map("n", "<leader>:", action("workbench.action.showCommands"), "Command History")
  map("n", "<leader>.", action("workbench.action.files.newUntitledFile"), "Toggle Scratch Buffer")
  map("n", "<leader>?", pick_leader_keymap, "Buffer Keymaps")
  map("n", "<leader>e", action("workbench.view.explorer"), "Explorer NeoTree")
  map("n", "<leader>n", action("notifications.showList"), "Notification History")

  -- Buffers: VS Code editors. vscode-neovim gives every editor its own nvim
  -- window, so nvim's alternate file (`:b#`) has nothing to go back to; the
  -- quick-open-and-accept pair walks VS Code's MRU list, which reorders on
  -- every switch, so pressing it twice comes back like `:b#` does.
  map(
    "n",
    "<leader>bb",
    actions({
      "workbench.action.quickOpenPreviousRecentlyUsedEditorInGroup",
      "workbench.action.acceptSelectedQuickOpenItem",
    }),
    "Switch to Last Buffer"
  )
  map("n", "<leader>bd", action("workbench.action.closeActiveEditor"), "Delete Buffer")
  map("n", "<leader>bD", action("workbench.action.closeActiveEditor"), "Delete Buffer and Window")
  map("n", "<leader>bo", action("workbench.action.closeOtherEditors"), "Delete Other Buffers")
  map("n", "<leader>br", action("workbench.action.closeEditorsToTheRight"), "Delete Buffers to the Right")
  map("n", "<leader>bl", action("workbench.action.closeEditorsToTheLeft"), "Delete Buffers to the Left")
  map("n", "<leader>bx", confirm_close_all, "Delete All Buffers (Confirm)")
  map("n", "<leader>bp", toggle_pin, "Toggle Pin")
  map("n", "<leader>bP", close_unpinned, "Delete Non-Pinned Buffers")
  map("n", "<leader>bj", action("workbench.action.showEditorsInActiveGroup"), "Pick Buffer")
  map("n", "<leader>be", action("workbench.files.action.focusOpenEditorsView"), "Buffer Explorer")
  map("n", "<S-h>", action("workbench.action.previousEditor"), "Prev Buffer")
  map("n", "<S-l>", action("workbench.action.nextEditor"), "Next Buffer")
  map("n", "[b", action("workbench.action.previousEditor"), "Prev Buffer")
  map("n", "]b", action("workbench.action.nextEditor"), "Next Buffer")

  -- Harpoon (vscode-harpoon; VS Code only). Kept on the keys nvim leaves free;
  -- the quick pick moved off <leader>p, which is nvim's Python/Packages group.
  map("n", "<leader>a", action("vscode-harpoon.addEditor"), "Harpoon: Add File")
  map("n", "<leader>h", action("vscode-harpoon.editEditors"), "Harpoon: Edit List")
  map("n", "<leader>H", action("vscode-harpoon.editorQuickPick"), "Harpoon: Quick Pick")
  for i = 1, 5 do
    map("n", "<leader>" .. i, action("vscode-harpoon.gotoEditor" .. i), "Harpoon: File " .. i)
  end

  -- Code (lspsaga and LazyVim's LSP keys)
  map({ "n", "x" }, "<leader>ca", action("editor.action.quickFix"), "Code Action")
  map("n", "<leader>cA", action("editor.action.sourceAction"), "Source Action")
  map("n", "<leader>cc", action("codelens.showLensesInCurrentLine"), "Run Codelens")
  map("n", "<leader>cd", action("editor.action.showHover"), "Line Diagnostics")
  map("n", "<leader>cD", action("editor.action.fixAll"), "Fix all diagnostics")
  map({ "n", "x" }, "<leader>cf", format, "Format")
  map({ "n", "x" }, "<leader>mp", format, "Format file or range (in visual mode)")
  map("n", "<leader>cm", action("workbench.view.extensions"), "Mason")
  map(
    "n",
    "<leader>cM",
    action("editor.action.sourceAction", { kind = "source.addMissingImports", apply = "first" }),
    "Add missing imports"
  )
  map("n", "<leader>co", action("editor.action.organizeImports"), "Organize Imports")
  map("n", "<leader>cr", action("editor.action.rename"), "Rename")
  -- renameFile acts on the explorer's selection, so reveal the file there first
  map(
    "n",
    "<leader>cR",
    actions({ "workbench.files.action.showActiveFileInExplorer", "renameFile" }),
    "Rename File"
  )
  map("n", "<leader>cs", action("editor.action.triggerParameterHints"), "Signature Help")
  map("n", "<leader>cS", action("references-view.findReferences"), "LSP references/definitions/... (Trouble)")
  map("n", "<leader>cV", action("typescript.selectTypeScriptVersion"), "Select TS workspace version")

  -- LSP. gd, K and gf come from vscode-neovim; gD and gh are rebound because
  -- this config means declaration and lspsaga's peek by them.
  map("n", "gr", action("editor.action.goToReferences"), "References", { nowait = true })
  map("n", "gI", action("editor.action.goToImplementation"), "Goto Implementation")
  map("n", "gy", action("editor.action.goToTypeDefinition"), "Goto T[y]pe Definition")
  map("n", "gD", action("editor.action.revealDeclaration"), "Goto Declaration")
  map("n", "gh", action("editor.action.peekDefinition"), "Peek Definition")
  map("n", "gK", action("editor.action.triggerParameterHints"), "Signature Help")
  map("n", "]]", action("editor.action.wordHighlight.next"), "Next Reference")
  map("n", "[[", action("editor.action.wordHighlight.prev"), "Prev Reference")

  -- wildfire: treesitter incremental selection -> VS Code smart select
  map("n", "gn", action("editor.action.smartSelect.expand"), "Init Selection")
  map("x", "]]", action("editor.action.smartSelect.expand"), "Increment Selection")
  map("x", "[[", action("editor.action.smartSelect.shrink"), "Decrement Selection")

  -- Comments. gc/gcc stay vscode-neovim's (VS Code's language-aware comment);
  -- Comment.nvim itself is not loaded here. Its gC has no port: the
  -- __flip_flop_comment it calls is not defined anywhere in this config.
  map("n", "gcb", comment_backup, "Comment: create backup")
  map("n", "gcA", function()
    require("plugins.comment.utils").append_eol_comment()
  end, "Comment at end of line")
  map("n", "gco", comment_line("editor.action.insertLineAfter"), "Add Comment Below")
  map("n", "gcO", comment_line("editor.action.insertLineBefore"), "Add Comment Above")

  -- Diagnostics, quickfix, todo. VS Code cannot filter marker navigation by
  -- severity, so ]e and ]w walk every diagnostic, the same as ]d.
  for _, key in ipairs({ "d", "e", "w" }) do
    map("n", "]" .. key, action("editor.action.marker.next"), "Next Diagnostic")
    map("n", "[" .. key, action("editor.action.marker.prev"), "Prev Diagnostic")
  end
  map("n", "]q", action("search.action.focusNextSearchResult"), "Next Quickfix")
  map("n", "[q", action("search.action.focusPreviousSearchResult"), "Previous Quickfix")
  map("n", "]t", action("todo-tree.goToNext"), "Next Todo Comment")
  map("n", "[t", action("todo-tree.goToPrevious"), "Previous Todo Comment")
  map("n", "<leader>xx", action("workbench.actions.view.toggleProblems"), "Diagnostics (Trouble)")
  map("n", "<leader>xX", action("workbench.action.problems.focus"), "Buffer Diagnostics (Trouble)")
  map("n", "<leader>xq", action("workbench.view.search"), "Quickfix List")
  map("n", "<leader>xQ", action("workbench.view.search"), "Quickfix List (Trouble)")
  map("n", "<leader>xs", search_to_quickfix, "Search Matches to Quickfix")
  map("n", "<leader>xt", action("todo-tree-view.focus"), "Todo (Trouble)")
  map("n", "<leader>xT", action("todo-tree-view.focus"), "Todo/Fix/Fixme (Trouble)")

  -- File/find (telescope)
  map("n", "<leader>ff", action("workbench.action.quickOpen"), "Find files")
  map("n", "<leader>fF", action("workbench.action.quickOpen"), "Find Files (cwd)")
  map("n", "<leader>fb", action("workbench.action.showAllEditorsByMostRecentlyUsed"), "Find buffers")
  map("n", "<leader>fB", action("workbench.action.showAllEditors"), "Buffers (all)")
  map("n", "<leader>fg", action("workbench.action.quickTextSearch"), "Live grep")
  map("n", "<leader>fr", action("workbench.view.search"), "Resume last search")
  map("n", "<leader>fR", action("workbench.action.quickOpen"), "Recent (cwd)")
  map("n", "<leader>fo", action("workbench.action.openRecent"), "Old files")
  map("n", "<leader>ft", action("workbench.action.gotoSymbol"), "Treesitter symbols")
  map("n", "<leader>fs", action("workbench.action.gotoSymbol"), "Document symbols")
  map("n", "<leader>fS", action("workbench.action.showAllSymbols"), "Workspace symbols")
  map("n", "<leader>fh", action("workbench.action.openDocumentationUrl"), "Help tags")
  map("n", "<leader>fk", pick_leader_keymap, "Keymaps")
  map("n", "<leader>fC", action("workbench.action.showCommands"), "Commands")
  map("n", "<leader>fn", action("workbench.action.files.newUntitledFile"), "New File")
  map("n", "<leader>fp", action("copyRelativeFilePath"), "Copy Relative Path to Clipboard")
  map("n", "<leader>fT", action("workbench.action.terminal.toggleTerminal"), "Terminal (cwd)")
  map("n", "<C-/>", action("workbench.action.terminal.toggleTerminal"), "Terminal (Root Dir)")

  -- Search
  map("n", "<leader>sg", action("workbench.action.findInFiles"), "Grep (Root Dir)")
  map("n", "<leader>sG", action("workbench.action.findInFiles"), "Grep (cwd)")
  -- In visual mode findInFiles seeds its query from the selection by itself.
  map("n", "<leader>sw", grep_word, "Visual selection or word (Root Dir)")
  map("n", "<leader>sW", grep_word, "Visual selection or word (cwd)")
  map("x", "<leader>sw", action("workbench.action.findInFiles"), "Visual selection or word (Root Dir)")
  map("x", "<leader>sW", action("workbench.action.findInFiles"), "Visual selection or word (cwd)")
  map("n", "<leader>sb", action("actions.find"), "Buffer Lines")
  map("n", "<leader>sB", action("workbench.action.findInFiles", { onlyOpenEditors = true }), "Grep Open Buffers")
  map({ "n", "x" }, "<leader>sr", search_and_replace, "Search and Replace")
  map("n", "<leader>sR", action("workbench.view.search"), "Resume")
  map("n", "<leader>sc", action("workbench.action.showCommands"), "Command History")
  map("n", "<leader>sC", action("workbench.action.showCommands"), "Commands")
  map("n", "<leader>sd", action("workbench.action.problems.focus"), "Diagnostics")
  map("n", "<leader>sD", action("workbench.action.problems.focus"), "Buffer Diagnostics")
  map("n", "<leader>sh", action("workbench.action.openDocumentationUrl"), "Help Pages")
  map("n", "<leader>sk", pick_leader_keymap, "Keymaps")
  map("n", "<leader>sq", action("workbench.view.search"), "Quickfix List")
  map("n", "<leader>ss", action("workbench.action.gotoSymbol"), "LSP Symbols")
  map("n", "<leader>sS", action("workbench.action.showAllSymbols"), "LSP Workspace Symbols")
  map("n", "<leader>st", action("todo-tree-view.focus"), "Todo (Telescope)")
  map("n", "<leader>sT", action("todo-tree-view.focus"), "Todo/Fix/Fixme")
  -- VS Code's local history is the closest thing to an undo tree
  map("n", "<leader>su", action("timeline.focus"), "Undotree")
  map("n", "<leader>snl", action("notifications.showList"), "Noice Last Message")
  map("n", "<leader>snh", action("notifications.showList"), "Noice History")
  map("n", "<leader>sna", action("notifications.showList"), "Noice All")
  map("n", "<leader>snd", action("notifications.clearAll"), "Dismiss All")

  -- Git (neogit, gitsigns, snacks' git pickers, octo)
  map("n", "<leader>gg", action("workbench.view.scm"), "Open Neogit")
  map("n", "<leader>gG", lazygit, "Lazygit")
  map("n", "<leader>gs", action("workbench.view.scm"), "Git Status")
  map("n", "<leader>ge", action("workbench.view.scm"), "Git Explorer")
  map("n", "<leader>gb", action("gitlens.showLineHistoryView"), "Git Blame Line")
  map("n", "<leader>gf", action("gitlens.showFileHistoryView"), "Git Current File History")
  map("n", "<leader>gl", action("git-graph.view"), "Git Log")
  map("n", "<leader>gL", action("gitlens.showCommitsView"), "Git Log (cwd)")
  map({ "n", "x" }, "<leader>gB", action("gitlens.openFileOnRemote"), "Git Browse (open)")
  map({ "n", "x" }, "<leader>gY", action("gitlens.copyRemoteFileUrlToClipboard"), "Git Browse (copy)")
  map("n", "<leader>gd", action("git.viewChanges"), "Git Diff (hunks)")
  map("n", "<leader>gD", action("gitlens.compareHeadWith"), "Git Diff (origin)")
  map("n", "<leader>gS", action("gitlens.showStashesView"), "Git Stash")
  map("n", "<leader>gi", action("issues:github.focus"), "GitHub Issues (open)")
  map("n", "<leader>gI", action("issues:github.focus"), "GitHub Issues (all)")
  map("n", "<leader>gp", action("pr:github.focus"), "GitHub Pull Requests (open)")
  map("n", "<leader>gP", action("pr:github.focus"), "GitHub Pull Requests (all)")
  map({ "n", "x" }, "<leader>ghs", action("git.stageSelectedRanges"), "Stage Hunk")
  map({ "n", "x" }, "<leader>ghr", action("git.revertSelectedRanges"), "Reset Hunk")
  map("n", "<leader>ghS", action("git.stage"), "Stage Buffer")
  map("n", "<leader>ghu", action("git.unstageSelectedRanges"), "Undo Stage Hunk")
  map("n", "<leader>ghR", action("git.clean"), "Reset Buffer")
  map("n", "<leader>ghp", action("editor.action.dirtydiff.next"), "Preview Hunk Inline")
  map("n", "<leader>ghb", action("gitlens.showQuickCommitDetails"), "Blame Line")
  map("n", "<leader>ghB", action("gitlens.toggleFileBlame"), "Blame Buffer")
  map("n", "<leader>ghd", action("git.openChange"), "Diff This")
  map("n", "<leader>ghD", action("gitlens.diffWithPrevious"), "Diff This ~")
  map("n", "]h", action("workbench.action.editor.nextChange"), "Next Hunk")
  map("n", "[h", action("workbench.action.editor.previousChange"), "Prev Hunk")
  -- The GitHub Pull Requests view groups PRs by "Waiting For My Review" and
  -- "Created By Me", so both octo searches land on it.
  map("n", "<leader>or", action("pr:github.focus"), "Octo: PRs Requesting My Review")
  map("n", "<leader>op", action("pr:github.focus"), "Octo: My Open PRs")
  map("n", "<leader>os", action("pr.openDescription"), "Octo: Start Review")

  -- Python
  map("n", "<leader>pym", function()
    local path = util.relative_path()
    if path then
      require("config.keymaps.python").copy_module_name(path)
    end
  end, "Copy Module Name")

  -- Quit/session
  map("n", "<leader>qq", action("workbench.action.closeWindow"), "Quit All")
  map("n", "<leader>qS", action("workbench.action.openRecent"), "Select Session")

  -- Tests (neotest -> VS Code's Testing view). neotest's [e/]e are shadowed by
  -- LazyVim's error jumps in nvim, so only the failed-test pair is ported.
  map("n", "<leader>tr", action("testing.runAtCursor"), "Run Nearest")
  map("n", "<leader>tf", action("testing.runCurrentFile"), "Run File")
  map("n", "<leader>to", action("testing.openOutputPeek"), "Show Output")
  map("n", "<leader>tO", action("testing.showMostRecentOutput"), "Show Output (enter)")
  map("n", "<leader>tp", action("testing.showMostRecentOutput"), "Toggle Output Panel")
  map("n", "]E", action("testing.goToNextMessage"), "Next Failed Test")
  map("n", "[E", action("testing.goToPreviousMessage"), "Prev Failed Test")

  -- UI toggles
  map("n", "<leader>uw", action("editor.action.toggleWordWrap"), "Toggle Wrap")
  map("n", "<leader>us", action("cSpell.toggleEnableSpellChecker"), "Toggle Spelling")
  map("n", "<leader>ud", toggle_diagnostics, "Toggle Diagnostics")
  map("n", "<leader>uh", function()
    util.toggle_config("editor.inlayHints.enabled", "on", "off", "Inlay hints")
  end, "Toggle Inlay Hints")
  map("n", "<leader>uf", function()
    util.toggle_config("editor.formatOnSave", true, false, "Format on save")
  end, "Toggle Auto Format (Global)")
  map("n", "<leader>uF", toggle_format_language, "Toggle Auto Format (Buffer)")
  map("n", "<leader>ug", function()
    util.toggle_config("editor.guides.indentation", true, false, "Indent guides")
  end, "Toggle Indent Guides")
  map("n", "<leader>uA", function()
    util.toggle_config("workbench.editor.showTabs", "multiple", "none", "Tabline")
  end, "Toggle Tabline")
  map("n", "<leader>uG", function()
    util.toggle_config("scm.diffDecorations", "all", "none", "Git signs")
  end, "Toggle Git Signs")
  map("n", "<leader>uS", function()
    util.toggle_config("editor.smoothScrolling", true, false, "Smooth scroll")
  end, "Toggle Smooth Scroll")
  -- mini.pairs does nothing here: VS Code does the typing in insert mode
  map("n", "<leader>up", function()
    util.toggle_config("editor.autoClosingBrackets", "languageDefined", "never", "Auto pairs")
  end, "Toggle Mini Pairs")
  map("n", "<leader>ub", action("workbench.action.toggleLightDarkThemes"), "Toggle Dark Background")
  map("n", "<leader>uC", action("workbench.action.selectTheme"), "Colorschemes")
  map("n", "<leader>uz", action("workbench.action.toggleZenMode"), "Toggle Zen Mode")
  map("n", "<leader>uZ", action("workbench.action.toggleMaximizeEditorGroup"), "Toggle Zoom")
  map("n", "<leader>un", action("notifications.clearAll"), "Dismiss All Notifications")
  map("n", "<leader>ui", action("editor.action.inspectTMScopes"), "Inspect Pos")
  map("n", "<leader>uI", action("editor.action.inspectTMScopes"), "Inspect Tree")

  -- Windows: VS Code editor groups
  map("n", "<leader>wm", action("workbench.action.toggleMaximizeEditorGroup"), "Toggle Zoom")
  map("n", "<leader>wp", pick_window, "Pick window")
  map("n", "<leader>w>", action("workbench.action.increaseViewWidth"), "Increase window width")
  map("n", "<leader>w<", action("workbench.action.decreaseViewWidth"), "Decrease window width")
  map("n", "<leader>w+", action("workbench.action.increaseViewHeight"), "Increase window height")

  -- Tabs: VS Code has no tab pages. Same mapping vscode-neovim gives :tabnew,
  -- :tabnext and friends -- LazyVim's <cmd>tabnext<cr> would reach nvim's real
  -- tab pages, since the command-line aliases only apply to typed commands.
  map("n", "<leader><tab><tab>", action("workbench.action.files.newUntitledFile"), "New Tab")
  map("n", "<leader><tab>]", action("workbench.action.nextEditorInGroup"), "Next Tab")
  map("n", "<leader><tab>[", action("workbench.action.previousEditorInGroup"), "Previous Tab")
  map("n", "<leader><tab>f", action("workbench.action.firstEditorInGroup"), "First Tab")
  map("n", "<leader><tab>l", action("workbench.action.lastEditorInGroup"), "Last Tab")
  map("n", "<leader><tab>o", action("workbench.action.closeOtherEditors"), "Close Other Tabs")
  map("n", "<leader><tab>d", action("workbench.action.closeActiveEditor"), "Close Tab")

  -- No VS Code counterpart. Most open a snacks picker or float, which VS Code
  -- cannot show -- and an invisible picker keeps swallowing keystrokes; the
  -- rest toggle nvim rendering that VS Code does not use. All of these are set
  -- in VS Code too (LazyVim core, or snacks' own keys), so each del is real.
  local nvim_only = {
    "<leader>bi", -- delete invisible buffers: would hit the buffers behind VS Code's background tabs
    "<leader>xl", -- location list window
    "<leader>ua", -- animations
    "<leader>uc", -- conceal (vscode-neovim pins conceallevel to 0)
    "<leader>uD", -- dimming
    "<leader>uT", -- treesitter highlight (the vscode extra turns it off)
    "<leader>S", -- scratch picker
    "<leader>L", -- LazyVim changelog
    "<leader>s\"", -- registers
    "<leader>s/", -- search history
    "<leader>sa", -- autocmds
    "<leader>sH", -- highlights
    "<leader>si", -- icons
    "<leader>sj", -- jumps
    "<leader>sl", -- location list
    "<leader>sm", -- marks
    "<leader>sM", -- man pages
    "<leader>sp", -- plugin specs
    "<leader>fc", -- nvim config files
    "<leader>dpp", -- profiler
    "<leader>dph",
    "<leader>dps",
  }
  for _, lhs in ipairs(nvim_only) do
    pcall(vim.keymap.del, "n", lhs)
  end
end

return M
