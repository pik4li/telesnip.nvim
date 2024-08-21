local M = {}

M.setup = function(user_opts)
	local opts = user_opts or {}
	M.snippet_path = opts.snippet_path or (vim.fn.stdpath("data") .. "/lazy/telesnip.nvim/lua/telesnip/snippets/")
	vim.notify("Telesnip plugin loaded. Snippet path set to: " .. M.snippet_path)
end

local function load_snippets(language)
	local path = M.snippet_path .. language .. "/"
	vim.notify("Loading snippets from path: " .. path)
	local snippets = {}

	if vim.fn.isdirectory(path) == 0 then
		vim.notify("Directory does not exist: " .. path, vim.log.levels.WARN)
		return {}
	end

	-- Process all files in the directory
	for _, file in ipairs(vim.fn.readdir(path)) do
		local full_path = path .. file
		vim.notify("Attempting to load snippet file: " .. full_path)

		-- Read the file content
		local file_handle = io.open(full_path, "r")
		if file_handle then
			local current_snippet = nil
			local plugin_name = nil
			for line in file_handle:lines() do
				if line:match("^# <name>$") then
					plugin_name = "Telesnip"
					vim.notify("Plugin name set to: " .. plugin_name)
				elseif line:match("^-- <name>$") then
					plugin_name = "Telesnip"
					vim.notify("Plugin name set to: " .. plugin_name)
				elseif line:match("^---$") then
					if current_snippet then
						table.insert(snippets, current_snippet)
						current_snippet = nil
					end
				elseif not current_snippet then
					current_snippet = { title = line, content = "" }
				else
					current_snippet.content = current_snippet.content .. line .. "\n"
				end
			end
			if current_snippet then
				table.insert(snippets, current_snippet)
			end
			file_handle:close()
		else
			vim.notify("Failed to open snippet file: " .. full_path, vim.log.levels.ERROR)
		end
	end

	return snippets
end

M.snippets = function()
	local current_filetype = vim.bo.filetype
	local snippets = load_snippets(current_filetype)

	if #snippets == 0 then
		vim.notify("No snippets found for filetype: " .. current_filetype, vim.log.levels.WARN)
		return
	end

	require("telescope.pickers")
		.new({}, {
			prompt_title = "Snippets (" .. current_filetype .. ")",
			finder = require("telescope.finders").new_table({
				results = snippets,
				entry_maker = function(entry)
					return {
						value = entry.content,
						display = entry.title,
						ordinal = entry.title,
					}
				end,
			}),
			sorter = require("telescope.config").values.generic_sorter({}),
			previewer = require("telescope.previewers").new_buffer_previewer({
				define_preview = function(self, entry)
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(entry.value, "\n"))
					local filetype = current_filetype
					vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", filetype)
					vim.api.nvim_buf_set_option(self.state.bufnr, "modifiable", false)
				end,
			}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					local selection = require("telescope.actions.state").get_selected_entry()
					require("telescope.actions").close(prompt_bufnr)
					vim.api.nvim_put(vim.split(selection.value, "\n"), "", true, true)
					vim.notify("Snippet inserted from the " .. current_filetype .. " directory.")
				end)
				return true
			end,
		})
		:find()
end

M.save_custom_snippet = function()
	local current_filetype = vim.bo.filetype
	local custom_snippet_path = M.snippet_path .. "custom" .. "." .. current_filetype

	-- Get the selected text
	local selected_text = ""
	local success, result = pcall(function()
		return vim.api.nvim_exec('normal! gv"zy', true)
	end)
	if success then
		selected_text = vim.fn.getreg("z")
	else
		vim.notify("No text selected to create a custom snippet.", vim.log.levels.WARN)
		return
	end

	local function_name = vim.fn.input("Enter a name for the custom snippet: ")
	if function_name == "" then
		vim.notify("No name provided for the custom snippet.", vim.log.levels.WARN)
		return
	end

	local snippet_content = "-- " .. function_name .. "\n \n" .. selected_text .. "\n---\n"

	local file_handle = io.open(custom_snippet_path, "a")
	if file_handle then
		file_handle:write(snippet_content .. "\n")
		file_handle:close()
		vim.notify("Custom snippet saved to: " .. custom_snippet_path)
	else
		vim.notify("Failed to write the custom snippet to: " .. custom_snippet_path, vim.log.levels.ERROR)
	end
end

return M
