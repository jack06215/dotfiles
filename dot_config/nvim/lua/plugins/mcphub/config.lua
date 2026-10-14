return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  -- Global install (lands in $XDG_DATA_HOME/npm/bin via npmrc); re-run on
  -- plugin updates so mcp-hub stays at the version the plugin requires.
  build = "npm install -g mcp-hub@latest",
  version = false,
  opts = {
    use_bundled_binary = false, -- Use the global `mcp-hub` on PATH
    ---Chat-plugin related options-----------------
    auto_approve = true, -- Auto approve mcp tool calls
    auto_toggle_mcp_servers = true, -- Let LLMs start and stop MCP servers automatically
    log = {
      level = vim.g.personal_options.debug.avante and vim.log.levels.DEBUG or vim.log.levels.WARN,
      to_file = false,
      file_path = nil,
      prefix = "MCPHub",
    },
    extensions = {
      avante = {
        make_slash_commands = true, -- make /slash commands from MCP server prompts
      },
      copilotchat = {
        enabled = true,
        convert_tools_to_functions = true, -- Convert MCP tools to CopilotChat functions
        convert_resources_to_functions = true, -- Convert MCP resources to CopilotChat functions
        add_mcp_prefix = false, -- Add "mcp_" prefix to function names
      },
    },
  },
}
