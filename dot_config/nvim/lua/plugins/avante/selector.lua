-- Snacks picker for avante's selectors (@file, models, history).
--
-- Avante's own snacks provider (ui/selector/providers/snacks.lua) uses a live
-- finder: every keystroke re-filters by plain substring and builds the preview
-- of every match up front -- reading the whole file and running filetype
-- detection on a scratch buffer. On a ~3k-file repo that is ~0.8s per key.
-- Here snacks gets the list once and fuzzy-matches it itself, and a preview is
-- built only for the item under the cursor.

---@param selector avante.ui.Selector
return function(selector)
  local completed = false

  local function finder()
    local selected = {}
    for _, id in ipairs(selector.selected_item_ids) do
      selected[id] = true
    end
    local items = {}
    for i, item in ipairs(selector.items) do
      if not selected[item.id] then
        items[#items + 1] = { idx = i, text = item.title, item = item }
      end
    end
    return items
  end

  local preview = selector.get_preview_content
    and function(ctx)
      if not ctx.item.preview then
        local text, ft = selector.get_preview_content(ctx.item.item.id)
        ctx.item.preview = { text = text or "", ft = ft }
      end
      return Snacks.picker.preview.preview(ctx)
    end

  Snacks.picker.pick(vim.tbl_deep_extend("force", {
    source = "select",
    finder = finder,
    format = Snacks.picker.format.ui_select({ format_item = function(item) return item.title end }),
    title = selector.title,
    preview = preview,
    layout = { preset = "default" },
    confirm = function(picker)
      if completed then return end
      completed = true
      picker:close()
      local ids = vim.tbl_map(function(item) return item.item.id end, picker:selected({ fallback = true }))
      selector.on_select(ids)
    end,
    on_close = function()
      if completed then return end
      completed = true
      vim.schedule(function() selector.on_select(nil) end)
    end,
    actions = {
      -- History selector: <C-Del> removes entries, as in avante's provider
      delete_selection = function(picker)
        local selections = picker:selected({ fallback = true })
        if #selections == 0 or not selector.on_delete_item then return end
        vim.ui.input({ prompt = "Remove selection? (" .. #selections .. " items) [y/N]" }, function(input)
          if not (input and input:lower() == "y") then return end
          for _, selection in ipairs(selections) do
            selector.on_delete_item(selection.item.id)
            for i, item in ipairs(selector.items) do
              if item.id == selection.item.id then
                table.remove(selector.items, i)
                break
              end
            end
          end
          picker:refresh()
        end)
      end,
    },
    win = {
      input = {
        keys = {
          ["<C-DEL>"] = { "delete_selection", mode = { "i", "n" } },
        },
      },
    },
  }, selector.provider_opts))
end
