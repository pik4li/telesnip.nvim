local M = {}

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

local function handle_placeholders(snippet_content)
	-- Find all placeholders like ${n:word} and process them
	local placeholders = {}
	local index = 0
	local modified_snippet = snippet_content:gsub("%${(%d+):([^}]+)}", function(number, text)
		index = index + 1
		table.insert(placeholders, { number = tonumber(number), text = text, index = index })
		return text -- Replace the placeholder with just the word
	end)

	-- Insert the snippet content without placeholders
	vim.api.nvim_put(vim.split(modified_snippet, "\n"), "", false, true)

	if #placeholders > 0 then
		-- Sort placeholders by number for sequential navigation
		table.sort(placeholders, function(a, b)
			return a.number < b.number
		end)

		-- Jump to the first placeholder and set up insert mode
		local first_placeholder = placeholders[1]
		local line, col = unpack(vim.fn.searchpos(first_placeholder.text, "cn"))

		if line > 0 and col > 0 then
			vim.api.nvim_win_set_cursor(0, { line, col - 1 })
			vim.cmd("startinsert!")
		end

		-- Set up mappings for navigating between placeholders
		vim.cmd([[nnoremap <silent> <Tab> :lua require('telesnip').jump_to_next_placeholder()<CR>]])
		vim.cmd([[inoremap <silent> <Tab> <Esc>:lua require('telesnip').jump_to_next_placeholder()<CR>]])

		-- Set up autocommands to remove the placeholder text when typing
		vim.cmd([[
      augroup TelesnipPlaceholder
        autocmd!
        autocmd InsertCharPre * lua require('telesnip').remove_placeholder()
      augroup END
    ]])
	end
end

local active_placeholder = nil

M.remove_placeholder = function()
	if active_placeholder then
		local line, col = unpack(vim.api.nvim_win_get_cursor(0))
		local current_line = vim.fn.getline(line)

		-- Find the position of the active placeholder text
		local placeholder_pos = string.find(current_line, vim.pesc(active_placeholder.text), col)

		if placeholder_pos then
			-- Replace the placeholder text with what the user is typing
			local new_line = current_line:sub(1, placeholder_pos - 1) .. current_line:sub(col)
			vim.api.nvim_buf_set_lines(0, line - 1, line, false, { new_line })
			vim.api.nvim_win_set_cursor(0, { line, placeholder_pos - 1 })
			-- Clear active placeholder
			active_placeholder = nil

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
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	local current_line = vim.fn.getline(line)

	-- Find the next placeholder position
	local next_placeholder_pos = string.find(current_line, "%${%d+:[^}]+}", col + 1)
	if next_placeholder_pos then
		vim.api.nvim_win_set_cursor(0, { line, next_placeholder_pos })
		vim.cmd("startinsert!")
		active_placeholder = { text = current_line:match("%${%d+:([^}]+)}", next_placeholder_pos) }
	else
		-- If no more placeholders in current line, search in next lines
		local next_line = line + 1
		while next_line <= vim.fn.line("$") do
			local next_line_content = vim.fn.getline(next_line)
			local next_pos = string.find(next_line_content, "%${%d+:([^}]+)}")
			if next_pos then
				vim.api.nvim_win_set_cursor(0, { next_line, next_pos })
				vim.cmd("startinsert!")
				active_placeholder = { text = next_line_content:match("%${%d+:([^}]+)}", next_pos) }
				break
			end
			next_line = next_line + 1
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

	-- Create the directory if it doesn't exist
	vim.fn.mkdir(M.custom_snippet_path, "p")

	-- Get the selected text in visual mode, including full line selection with <S-v>
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

	-- Use Telescope to preview the snippet and input the name
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

					-- Format the snippet content and save it
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

					-- Return to original buffer and position
					vim.cmd("stopinsert") -- Ensure normal mode
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

create_commands()

return M
