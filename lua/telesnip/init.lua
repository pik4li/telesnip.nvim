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
					vim.api.nvim_put(vim.split(selection.value, "\n"), "", false, true)
					vim.notify("Snippet inserted: " .. selection.display)
					vim.cmd("stopinsert") -- Stay in normal mode
				end)
				return true
			end,
			layout_config = {
				preview_cutoff = 1,
				width = 0.8,
				height = 0.8,
				preview_height = 0.6,
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

					-- Define a table that maps filetypes to their respective comment syntax
					local comment_syntax = {
						sh = "# ",
						bash = "# ",
						zsh = "# ",
						yaml = "# ",
						yml = "# ",
						make = "# ",
						lua = "-- ",
						vim = "-- ",
						python = "# ",
						ini = "# ",
						toml = "# ",
						c = "// ",
						cpp = "// ",
						java = "// ",
						javascript = "// ",
						json = "// ",
						html = "<!-- ",
						markdown = "<!-- ",
						md = "<!-- ",
						css = "/* ",
						scss = "/* ",
						php = "-- ",
						sql = "-- ",
						bat = "REM ",
						-- Add more filetypes here as needed
					}

					-- Retrieve the appropriate comment syntax based on the current filetype
					local comment = comment_syntax[current_filetype] or ""

					-- Construct the snippet content
					local snippet_content = comment .. snippet_name .. "\n" .. selected_text .. "\n---"

					-- Format the snippet content and save it
					-- local snippet_content = "-- " .. snippet_name .. "\n" .. selected_text .. "\n---"
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
