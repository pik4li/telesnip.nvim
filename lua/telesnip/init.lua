local M = {}

local active_placeholder = nil
local placeholders = {}

local function create_commands()
	vim.api.nvim_create_user_command("TelesnipShowSnippets", function()
		require("telesnip").telesnip_show()
	end, {})
	vim.api.nvim_create_user_command("TelesnipCustomSnippet", function()
		require("telesnip").save_custom_snippet()
	end, {})
end

M.setup = function(opts)
	M.snippet_path = opts.snippet_path or (vim.fn.stdpath("data") .. "/lazy/telesnip.nvim/lua/telesnip/snippets/")
	M.custom_snippet_path = opts.custom_snippet_path or (vim.fn.stdpath("config") .. "/snippets/")
	vim.notify("Telesnip-Snippet path set to: " .. M.snippet_path)
	vim.notify("Custom Telesnip-Snippet path set to: " .. M.custom_snippet_path)

	create_commands()
end

local function load_snippets(language)
	local snippets = {}
	local plugin_snippet_file = M.snippet_path .. "snippets." .. language
	local custom_snippet_file = M.custom_snippet_path .. "custom." .. language

	local function load_from_file(file_path)
		if vim.fn.filereadable(file_path) == 1 then
			local file_handle = io.open(file_path, "r")
			if file_handle then
				local current_snippet = nil
				for line in file_handle:lines() do
					if line:match("^---$") then
						if current_snippet then
							table.insert(snippets, current_snippet)
							current_snippet = nil
						end
					elseif not current_snippet then
						current_snippet = { title = line:gsub("^%-%- ", ""), content = "" }
					else
						current_snippet.content = current_snippet.content .. line .. "\n"
					end
				end
				if current_snippet then
					table.insert(snippets, current_snippet)
				end
				file_handle:close()
				vim.notify("Snippets loaded from: " .. file_path)
			end
		end
	end

	load_from_file(plugin_snippet_file)
	load_from_file(custom_snippet_file)

	return snippets
end

local function display_virtual_text_at_placeholder(placeholder)
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	vim.api.nvim_buf_set_extmark(0, vim.api.nvim_create_namespace("Telesnip"), line - 1, col - 1, {
		virt_text = { { placeholder.text, "Comment" } },
		hl_mode = "combine",
		ephemeral = true,
	})
end

local function clear_virtual_text()
	vim.api.nvim_buf_clear_namespace(0, vim.api.nvim_create_namespace("Telesnip"), 0, -1)
end

local function handle_placeholders(snippet_content)
	-- Parse the snippet content and find placeholders
	placeholders = {}
	local index = 0
	local modified_snippet = snippet_content:gsub("%${(%d+):([^}]+)}", function(number, text)
		index = index + 1
		table.insert(placeholders, { number = tonumber(number), text = text, index = index })
		return text -- Replace placeholder with the text
	end)

	-- Insert modified snippet
	vim.api.nvim_put(vim.split(modified_snippet, "\n"), "", false, true)

	if #placeholders > 0 then
		-- Sort placeholders by number
		table.sort(placeholders, function(a, b)
			return a.number < b.number
		end)

		-- Jump to the first placeholder and display virtual text
		active_placeholder = placeholders[1]
		local line, col = unpack(vim.fn.searchpos(active_placeholder.text, "cn"))

		if line > 0 and col > 0 then
			vim.api.nvim_win_set_cursor(0, { line, col - 1 })
			vim.cmd("startinsert!")
			display_virtual_text_at_placeholder(active_placeholder)
		end

		-- Setup <Tab> to jump to next placeholder
		vim.cmd([[inoremap <silent> <Tab> <Esc>:lua require('telesnip').jump_to_next_placeholder()<CR>]])

		-- Setup autocommand to clear virtual text when typing
		vim.cmd([[
            augroup TelesnipPlaceholder
                autocmd!
                autocmd InsertCharPre * lua require('telesnip').remove_placeholder()
            augroup END
        ]])
	end
end

M.remove_placeholder = function()
	if active_placeholder then
		local line, col = unpack(vim.api.nvim_win_get_cursor(0))
		local current_line = vim.fn.getline(line)

		-- Find position of active placeholder text
		local placeholder_pos = string.find(current_line, vim.pesc(active_placeholder.text), col)
		if placeholder_pos then
			-- Replace the placeholder with what the user is typing
			local new_line = current_line:sub(1, placeholder_pos - 1) .. current_line:sub(col)
			vim.api.nvim_buf_set_lines(0, line - 1, line, false, { new_line })
			vim.api.nvim_win_set_cursor(0, { line, placeholder_pos - 1 })
			active_placeholder = nil

			-- Clear virtual text
			clear_virtual_text()

			-- Remove autocommand after first character is typed
			vim.cmd([[
                augroup TelesnipPlaceholder
                    autocmd!
                augroup END
            ]])
		end
	end
end

M.jump_to_next_placeholder = function()
	local current_placeholder = nil
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	clear_virtual_text()

	for i, placeholder in ipairs(placeholders) do
		if line == vim.fn.line(".") and col == vim.fn.col(".") - 1 then
			current_placeholder = i
		end
	end

	if current_placeholder and placeholders[current_placeholder + 1] then
		active_placeholder = placeholders[current_placeholder + 1]
	else
		active_placeholder = placeholders[1]
	end

	if active_placeholder then
		local line, col = unpack(vim.fn.searchpos(active_placeholder.text, "cn"))
		if line > 0 and col > 0 then
			vim.api.nvim_win_set_cursor(0, { line, col - 1 })
			vim.cmd("startinsert!")
			display_virtual_text_at_placeholder(active_placeholder)
		end
	end
end

M.telesnip_show = function()
	local current_filetype = vim.bo.filetype
	local snippets = load_snippets(current_filetype)

	if #snippets == 0 then
		vim.notify("No snippets found for filetype: " .. current_filetype, vim.log.levels.WARN)
		return
	end

	local telescope = require("telescope")
	if not telescope then
		vim.notify("Telescope is not available. Please ensure it's installed.", vim.log.levels.ERROR)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = "Snippets (" .. current_filetype .. ")",
			finder = finders.new_table({
				results = snippets,
				entry_maker = function(entry)
					return {
						value = entry.content,
						display = entry.title,
						ordinal = entry.title .. " " .. entry.content,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = require("telescope.previewers").new_buffer_previewer({
				title = "Snippet Preview",
				dyn_title = function(_, entry)
					return entry.display
				end,
				define_preview = function(self, entry)
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(entry.value, "\n"))
					vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", current_filetype)
					vim.api.nvim_buf_set_option(self.state.bufnr, "modifiable", false)
				end,
			}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					handle_placeholders(selection.value)
					vim.notify("Snippet inserted: " .. selection.display)
				end)
				return true
			end,
			layout_config = {
				preview_cutoff = 1,
				width = 0.8,
				height = 0.8,
				preview_height = 0.5,
			},
			layout_strategy = "vertical",
		})
		:find()
end

M.save_custom_snippet = function()
	local current_filetype = vim.bo.filetype
	local custom_snippet_file_path = M.custom_snippet_path .. "custom." .. current_filetype

	vim.fn.mkdir(M.custom_snippet_path, "p")

	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local lines = vim.fn.getline(start_pos[2], end_pos[2])
	local selected_text = table.concat(lines, "\n")

	if selected_text == "" then
		vim.notify("No text selected to create a custom snippet.", vim.log.levels.WARN)
		return
	end

	local telescope = require("telescope")
	if not telescope then
		vim.notify("Telescope is not available. Please ensure it's installed.", vim.log.levels.ERROR)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = "Save Custom Snippet",
			finder = finders.new_table({
				results = { selected_text },
				entry_maker = function(entry)
					return {
						value = entry,
						display = "Preview of Snippet",
						ordinal = entry,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = require("telescope.previewers").new_buffer_previewer({
				title = "Snippet Preview",
				define_preview = function(self, entry)
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(entry.value, "\n"))
					vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", current_filetype)
					vim.api.nvim_buf_set_option(self.state.bufnr, "modifiable", false)
				end,
			}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local snippet_name = action_state.get_current_line()
					if snippet_name == "" then
						vim.notify("No name provided for the custom snippet.", vim.log.levels.WARN)
						return
					end

					actions.close(prompt_bufnr)

					local snippet_content = "-- " .. snippet_name .. "\n" .. selected_text .. "\n---\n"
					local file_handle = io.open(custom_snippet_file_path, "a")
					if file_handle then
						file_handle:write(snippet_content .. "\n")
						file_handle:close()
						vim.notify("Custom snippet saved to: " .. custom_snippet_file_path)
					else
						vim.notify(
							"Failed to write the custom snippet to: " .. custom_snippet_file_path,
							vim.log.levels.ERROR
						)
					end

					vim.cmd("stopinsert")
				end)
				return true
			end,
			layout_config = {
				preview_cutoff = 1,
				width = 0.8,
				height = 0.8,
				preview_height = 0.5,
			},
			layout_strategy = "vertical",
		})
		:find()
end

return M
