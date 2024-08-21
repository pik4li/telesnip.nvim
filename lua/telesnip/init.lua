local M = {}

M.setup = function(user_opts)
	local opts = user_opts or {}
	M.snippet_path = opts.snippet_path or (vim.fn.stdpath("data") .. "/lazy/telesnip.nvim/lua/telesnip/snippets/")
	vim.notify("Snippet path set to: " .. M.snippet_path)
end

local function load_snippets(language)
	local path = M.snippet_path .. language .. "/"
	vim.notify("Loading snippets from path: " .. path)
	local snippets = {}

	if vim.fn.isdirectory(path) == 0 then
		vim.notify("Directory does not exist: " .. path, vim.log.levels.ERROR)
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
			for line in file_handle:lines() do
				if line:match("^---$") then
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

M.telesnip_picker = function(language)
	local snippets = load_snippets(language)

	if #snippets == 0 then
		vim.notify("No snippets found for " .. language, vim.log.levels.WARN)
		return
	end

	require("telescope.pickers")
		.new({}, {
			prompt_title = "Snippets (" .. language .. ")",
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
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					local selection = require("telescope.actions.state").get_selected_entry()
					require("telescope.actions").close(prompt_bufnr)
					vim.api.nvim_put(vim.split(selection.value, "\n"), "", true, true)
				end)
				return true
			end,
		})
		:find()
end

return M
