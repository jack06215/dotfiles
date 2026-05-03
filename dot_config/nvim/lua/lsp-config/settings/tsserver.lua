local util = require("lspconfig.util")

return {
  root_dir = function(fname)
    if util.root_pattern("deno.json", "deno.jsonc")(fname) then
      return nil
    end

    return util.root_pattern("package.json")(fname)
  end,
  single_file_support = false,
}
