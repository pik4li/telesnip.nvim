local M = {}

local function get_snippets()
	local snippets = {}
	local base_path = vim.fn.stdpath("config") .. "/lua/telesnip/snippets/"
	local languages = vim.fn.readdir(base_path)

	for _, lang in ipairs(languages) do
		local path = base_path .. lang
		local files = vim.fn.glob(path .. "/*", false, true)
		for _, file in ipairs(files) do
			local snippet_name = vim.fn.fnamemodify(file, ":t")
			table.insert(snippets, {
				name = snippet_name,
				path = file,
				language = lang,
			})
		end
	end

	return snippets
end

local function save_snippet(snippet_content, snippet_name, language)
	local base_path = vim.fn.stdpath("config") .. "/lua/telesnip/snippets/"
	local file_path = base_path .. language .. "/" .. snippet_name .. ".txt"

	-- Write the snippet to the file
	vim.fn.writefile(snippet_content, file_path)
	print("Snippet saved as " .. snippet_name .. " in " .. language .. " folder.")
end

M.snippet_picker = function()
	local mode = vim.fn.mode()
	if mode == "v" then
		-- Capture the selected text in visual mode
		local snippet_content = vim.fn.getline("'<", "'>")
		local snippet_name = vim.fn.input("Enter snippet name: ")

		-- Optionally, ask for the language
		local language = vim.fn.input("Enter language folder name: ")

		-- Save the snippet
		save_snippet(snippet_content, snippet_name, language)
	else
		-- Normal snippet picker behavior
		local snippets = get_snippets()

		local opts = require("telescope.themes").get_dropdown({})
		require("telescope.pickers")
			.new(opts, {
				prompt_title = "Snippets",
				finder = require("telescope.finders").new_table({
					results = snippets,
					entry_maker = function(entry)
						return {
							value = entry,
							display = entry.name,
							ordinal = entry.name,
							path = entry.path,
						}
					end,
				}),
				sorter = require("telescope.config").values.generic_sorter(opts),
				previewer = require("telescope.previewers").new_buffer_previewer({
					define_preview = function(self, entry)
						local lines = vim.fn.readfile(entry.path)
						vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
						local ext = vim.fn.fnamemodify(entry.path, ":e")
						vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", ext)
					end,
				}),
				attach_mappings = function(_, map)
					map("i", "<CR>", function(prompt_bufnr)
						local selection = require("telescope.actions.state").get_selected_entry()
						local snippet_content = vim.fn.readfile(selection.path)

						-- Close Telescope prompt
						require("telescope.actions").close(prompt_bufnr)

						-- Insert snippet directly into the buffer
						vim.api.nvim_put(snippet_content, "l", true, true)

						-- Notify user
						print("Snippet inserted.")
					end)
					return true
				end,
			})
			:find()
	end
end

return M
