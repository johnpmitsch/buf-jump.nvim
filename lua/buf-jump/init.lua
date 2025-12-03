local M = {}

local jumping = false

local function get_win_data(winid)
	winid = winid or vim.api.nvim_get_current_win()
	if not M._win_data then
		M._win_data = {}
	end
	if not M._win_data[winid] then
		M._win_data[winid] = { history = {}, index = 0 }
	end
	return M._win_data[winid]
end

function M.add(bufnr)
	if jumping then
		return
	end

	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local bufinfo = vim.fn.getbufinfo(bufnr)
	if #bufinfo == 0 then
		return
	end
	bufinfo = bufinfo[1]

	local bufname = vim.api.nvim_buf_get_name(bufnr)
	if not bufinfo.listed or vim.trim(bufname) == "" then
		return
	end

	local data = get_win_data()
	local index = data.index + 1

	if vim.api.nvim_buf_is_valid(bufnr) then
		for i, b in ipairs(data.history) do
			if b == bufnr then
				table.remove(data.history, i)
				index = index - 1
				break
			end
		end
		data.index = index
		table.insert(data.history, index, bufnr)
	end
end

function M.remove(bufnr)
	if bufnr == -1 then
		for winid, _ in pairs(M._win_data or {}) do
			M._win_data[winid] = { history = {}, index = 0 }
		end
		return
	end

	for winid, data in pairs(M._win_data or {}) do
		for i = #data.history, 1, -1 do
			if data.history[i] == bufnr then
				table.remove(data.history, i)
			end
		end
		if data.index > #data.history then
			data.index = #data.history
		end
	end
end

function M.jump(opts)
	opts = opts or {}
	local direction = opts.direction or -1
	local count = opts.count or vim.v.count1

	local data = get_win_data()
	if #data.history == 0 then
		vim.notify("No buffer history", vim.log.levels.INFO)
		return
	end

	local new_index = data.index + (direction * count)

	-- Wrap index when out of bounds
	if new_index < 1 then
		new_index = #data.history
	elseif new_index > #data.history then
		new_index = 1
	end

	if new_index >= 1 and new_index <= #data.history then
		local target_buf = data.history[new_index]
		if vim.api.nvim_buf_is_valid(target_buf) then
			data.index = new_index
			jumping = true
			vim.api.nvim_set_current_buf(target_buf)
			jumping = false
			return
		else
			M.remove(target_buf)
			M.jump(opts)
			return
		end
	end
end

function M.back(count)
	M.jump({ direction = -1, count = count or vim.v.count1 })
end

function M.forward(count)
	M.jump({ direction = 1, count = count or vim.v.count1 })
end

function M.list()
	local win_type = vim.fn.win_gettype()
	if win_type ~= "" then
		return
	end

	local data = get_win_data()
	if #data.history == 0 then
		vim.notify("Buffer history is empty", vim.log.levels.INFO)
		return
	end

	local lines = { "Buffer History (* = current):" }
	for i, bufnr in ipairs(data.history) do
		local marker = i == data.index and "*" or " "
		local name = vim.api.nvim_buf_get_name(bufnr)
		if name == "" then
			name = "[No Name]"
		end
		name = vim.fn.fnamemodify(name, ":~:.")
		table.insert(lines, string.format("%3d %s %s", bufnr, marker, name))
	end
	print(table.concat(lines, "\n"))
end

function M.clear_win(winid)
	if M._win_data then
		M._win_data[winid] = nil
	end
end

function M.setup(opts)
	opts = opts or {}

	local group = vim.api.nvim_create_augroup("BufJump", { clear = true })

	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = group,
		callback = function(ev)
			M.add(ev.buf)
		end,
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(ev)
			M.remove(ev.buf)
		end,
	})

	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function(ev)
			local winid = tonumber(ev.match)
			if winid then
				M.clear_win(winid)
			end
		end,
	})

	vim.api.nvim_create_user_command("BufJumpList", M.list, {})
	vim.api.nvim_create_user_command("BufJumpBack", function(cmd)
		M.back(cmd.count > 0 and cmd.count or 1)
	end, { count = true })
	vim.api.nvim_create_user_command("BufJumpForward", function(cmd)
		M.forward(cmd.count > 0 and cmd.count or 1)
	end, { count = true })

	local mappings = opts.mappings
	if mappings == nil then
		mappings = true
	end

	if mappings then
		local keys = type(mappings) == "table" and mappings or {}
		vim.keymap.set("n", keys.list or "bjl", M.list, { desc = "List buffer history" })
		vim.keymap.set("n", keys.back or "bjp", M.back, { desc = "Previous buffer in history" })
		vim.keymap.set("n", keys.forward or "bjn", M.forward, { desc = "Next buffer in history" })
	end
end

return M
