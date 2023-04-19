local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")
local putils = require("telescope.previewers.utils")
local actions = require("telescope.actions")
local entry_display = require("telescope.pickers.entry_display")
local action_state = require("telescope.actions.state")
local ns_previewer = vim.api.nvim_create_namespace("telescope.previewers")
local status1, telescope = pcall(require, "telescope")
local org_sql = require("evidence.table")
local defer = require("utils.throttle-debounce")
local tools = require("utils.tools")
local index = require("evidence.index")

vim.api.nvim_command("highlight EvidenceWord guibg=red")

local entry_maker = function(entry)
  local content = entry.content:gsub("\n", "\\n")
  return {
    value = entry,
    ordinal = content,
    display = content,
  }
end

local function sql_find(prompt)
  return org_sql.find(50, "content like '%" .. prompt .. "%'")
end

local process_work = function(prompt, process_result, process_complete)
  local x = sql_find(prompt)
  if type(x) ~= "table" then
    s_prompt = ""
    process_complete()
    return
  end
  for _, v in ipairs(x) do
    process_result(entry_maker(v))
  end
  process_complete()
end

local fn, timer
local s_prompt = ""

local async_job = setmetatable({
  close = function()
    if timer ~= nil then
      timer:close()
    end
    --print("close")
  end,
  results = {},
  entry_maker = entry_maker,
}, {
  __call = function(_, prompt, process_result, process_complete)
    s_prompt = prompt
    if prompt == "" then
      process_complete()
      return
    end
    process_work(prompt, process_result, process_complete)
    -- TODO: throttle
    --if timer ~= nil then
    --  timer:close()
    --end
    --fn, timer = defer.throttle_trailing(process_work, 500)
    --fn(prompt, process_result, process_complete)
  end,
})

local function clear_match()
  vim.api.nvim_exec(
    [[
       for m in filter(getmatches(), { i, v -> l:v.group is? 'EvidenceWord' })
       call matchdelete(m.id)
       endfor
     ]],
    true
  )
end

local function live_fd(opts)
  pickers
    .new(opts, {
      prompt_title = "evidence",
      finder = async_job,
      sorter = conf.generic_sorter(opts), -- shouldn't this be default?
      previewer = previewers.new_buffer_previewer({
        keep_last_buf = true,
        get_buffer_by_name = function(_, entry)
          return entry.value.id
        end,
        define_preview = function(self, entry, status)
          --print(vim.inspect(entry))
          if s_prompt == "" then
            return
          end
          local formTbl = tools.str2table(entry.display)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, formTbl)
          putils.highlighter(self.state.bufnr, "org")
          vim.schedule(function()
            vim.api.nvim_buf_call(self.state.bufnr, function()
              clear_match()
              vim.api.nvim_command("call matchadd('EvidenceWord','" .. s_prompt .. "')")
            end)
          end)
        end,
      }),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          --print(vim.inspect(selection))
          index.content_overlay(selection.value)
        end)
        return true
      end,
    })
    :find()
end

local function find()
  local opts = {}
  return live_fd(opts)
end

return {
  find = find,
}