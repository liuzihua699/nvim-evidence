local instance = nil
local tools = require("utils.tools")

---@class _WinBuf
---@field initialized boolean
---@field win number
---@field buf number
local WinBuf = {}

function WinBuf:new()
	local data = { initialized = false }
	setmetatable(data, self)
	self.__index = self
	return data
end

function WinBuf:init()
	if self.initialized then
		return
	end
	self.win = -1
	self.buf = -1
	self.initialized = true
end

local function get_instance()
	if not instance then
		instance = WinBuf:new()
		WinBuf:init()
	end
	return instance
end

WinBuf.get_info = function()
	local this = get_instance()
	return {
		win = this.win,
		buf = this.buf,
	}
end

WinBuf.open_float_win = function()
	local this = get_instance()
	this.buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_option(this.buf, "bufhidden", "wipe")

	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")

	local win_height = math.ceil(height * 0.6 - 4)
	local win_width = math.ceil(width * 0.6)

	local row = math.ceil((height - win_height) / 2 - 1)
	local col = math.ceil((width - win_width) / 2)

	local opts = {
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
		border = "rounded",
	}

	this.win = vim.api.nvim_open_win(this.buf, true, opts)
	vim.api.nvim_win_set_option(this.win, "cursorline", true)
end

---@param winnr? number
---@return number
WinBuf._get_win_width = function(winnr)
	winnr = winnr or 0
	local winwidth = vim.api.nvim_win_get_width(winnr)

	local win_id
	if winnr == 0 then -- use current window
		win_id = vim.fn.win_getid()
	else
		win_id = vim.fn.win_getid(winnr)
	end

	local wininfo = vim.fn.getwininfo(win_id)[1]
	-- this encapsulates both signcolumn & numbercolumn (:h wininfo)
	local gutter_width = wininfo and wininfo.textoff or 0

	return winwidth - gutter_width
end

WinBuf.open_split_win = function()
	local this = get_instance()
	if this.win ~= -1 then
		local wininfo = vim.fn.getwininfo(this.win)[1]
		if wininfo ~= nil then
			vim.api.nvim_win_close(this.win, true)
			-- vim.cmd(":call nvim_win_close(" .. win .. ", v:true)")
		end
	end
	local cmd_by_split_mode = {
		horizontal = string.format("34split"),
		vertical = string.format("vsplit"),
	}

	local winwidth = this._get_win_width()
	if (winwidth / 2) >= 80 then
		vim.cmd(cmd_by_split_mode.vertical)
		vim.w.org_window_split_mode = "vertical"
	else
		vim.cmd(cmd_by_split_mode.horizontal)
		vim.w.org_window_split_mode = "horizontal"
	end
	this.win = vim.api.nvim_get_current_win()
	this.buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_win_set_buf(this.win, this.buf)
	vim.keymap.set("n", "q", ":call nvim_win_close(win_getid(), v:true)<CR>", { buffer = this.buf, silent = true })
end

local function view_content(form)
	if form == nil then
		return
	end
	local this = get_instance()
	local formTbl = tools.str2table(form)
	vim.api.nvim_buf_set_lines(this.buf, 0, -1, false, formTbl)
	vim.api.nvim_buf_set_option(this.buf, "modifiable", true)
	vim.api.nvim_buf_set_option(this.buf, "filetype", "org")
	vim.wo.number = true
	vim.wo.relativenumber = true
	vim.o.cursorcolumn = true
	vim.wo.cursorline = true
	vim.api.nvim_feedkeys("gg", "n", false)
	vim.wo.foldlevel = 1
	vim.api.nvim_feedkeys("za", "n", false)
	--vim.api.nvim_feedkeys("zx", "n", false)
end

---@class WinBuf
return {
	view_content = view_content,
}
