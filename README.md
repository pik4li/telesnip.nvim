# Telesnip.nvim

Telesnip.nvim is a Neovim plugin that integrates with Telescope to manage and insert code snippets with ease. Whether you're working on Bash, Lua, Python, or any other language, Telesnip allows you to quickly access, preview, and insert your snippets, or save new ones directly from your current buffer.

## Features

- **Snippet Picker**: Use Telescope to quickly find and insert snippets from your library.
- **Visual Mode Integration**: Select code in visual mode and save it as a snippet, complete with a name and language folder.
- **Automatic File Extensions**: Snippets are saved with the correct file extension based on the language.
- **Customizable**: Easily extend the plugin to support more languages and file types.

## Installation

Install using your favorite Neovim package manager:

### Using [Lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  "https://git.k4li.de/pika/telesnip.nvim",
  dependencies = "nvim-telescope/telescope.nvim",
  opts = {
    -- snippet_path = "/path/to/your/snippets",
    -- custom_snippet_path = "/path/to/your/custom/snippets",
  },
  config = function(_, opts)
    require("telesnip").setup(opts)
  end,
  keys = {
    { "<leader>S",  "<cmd>TelesnipShowSnippets<CR>",  desc = "Open Snippet Picker" },
    { "<leader>cs", "<cmd>TelesnipCustomSnippet<CR>", mode = "v", desc = "Save Custom Snippet" },
  },
}
```

## Usage

### Snippet Picker

- **Command**: `:Telescope telesnip`
- **Keybinding**: (Bind this command to a key of your choice in your Neovim config)

### Save Snippet (Visual Mode)

1. Select the code you want to save as a snippet in visual mode.
2. Press the keybinding you've set up for Telesnip in visual mode.
3. Enter the snippet name and the language folder when prompted.

## Configuration

To add more languages and customize file extensions, modify the `get_file_extension` function in the plugin code:

```lua
local function get_file_extension(language)
    local extensions = {
        bash = ".sh",
        lua = ".lua",
        python = ".py",
        javascript = ".js",
        php = ".php",
        -- Add more languages and their respective extensions here
    }
    return extensions[language] or ".txt"
end
```

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests for new features, bug fixes, or language support.

## License

MIT License. See `LICENSE` for more information.

### ToDo

- [x] Let telescope show preconfigured snippets out of the `telesnip/snippets/<language>/` directory
- [x] Paste the snippet in directly at your cursor
- [ ] Add snippets easily by selecting it in visual mode and calling the plugin as usual
- [ ] Understand the code 100%

```
### Next Steps:
1. **Test**: Make sure everything works as expected, including the visual mode functionality.
2. **Customize**: Adjust the language support and extensions in `get_file_extension`.
3. **Documentation**: Integrate the README with your repository.

This setup should provide the functionality you're looking for and make the plugin easier to use and extend.
```
