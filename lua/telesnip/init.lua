local M = {}

M.setup = function(opts)
	-- Set the snippet path, defaulting to the Lazy.nvim plugin path if not provided
	M.snippet_path = opts.snippet_path or vim.fn.stdpath("data") .. "/lazy/telesnip.nvim/lua/telesnip/snippets/"
end

local function load_snippets(language)
	local path = M.snippet_path .. language .. "/"
	local snippets = {}

	for _, file in ipairs(vim.fn.readdir(path)) do
		local full_path = path .. file
		local status, snippet_content = pcall(dofile, full_path)
		if status then
			table.insert(snippets, snippet_content)
		else
			print("Failed to load snippet from", full_path, ":", snippet_content)
		end
	end

	return snippets
end

M.snippet_picker = function()
	local current_filetype = vim.fn.expand("%:e")
	vim.notify("Detected file extension: " .. current_filetype)
	local snippets = load_snippets(current_filetype)

	if vim.tbl_isempty(snippets) then
		vim.notify("No snippets found for " .. current_filetype, vim.log.levels.WARN)
		return
	end

	require("telescope.pickers")
		.new({}, {
			prompt_title = "Snippets",
			finder = require("telescope.finders").new_table({
				results = vim.tbl_map(function(s)
					return s.name
				end, snippets),
			}),
			sorter = require("telescope.config").values.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				local function insert_snippet(selected_snippet)
					local snippet = vim.tbl_filter(function(s)
						return s.name == selected_snippet
					end, snippets)[1].snippet
					vim.api.nvim_put({ snippet }, "", true, true)
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
					vim.cmd("stopinsert")
				end

				map("i", "<CR>", function()
					local selection = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
					require("telescope.actions").close(prompt_bufnr)
					insert_snippet(selection.value)
				end)

				map("n", "<CR>", function()
					local selection = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
					require("telescope.actions").close(prompt_bufnr)
					insert_snippet(selection.value)
				end)

				return true
			end,
		})
		:find()
end

return M
