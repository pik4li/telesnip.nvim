# Telesnip.nvim

Telesnip.nvim is a Neovim plugin that integrates with Telescope to manage and insert code snippets with ease.
Whether you're working on Bash, Lua, Python, or any other language, Telesnip allows you to quickly access, preview, and insert your snippets, or save new ones directly from your current buffer.

## Features

- **Snippet Picker**: Use Telescope to quickly find and insert snippets from your library.
- **Visual Mode Integration**: Select code in visual mode and save it as a snippet.
- **Automatic File Extensions**: Snippets are saved with the correct file extension based on the language of the current buffer file.
- **Customizable**: Easily extend the plugin to support more languages and file types.

## Installation

Install using your favorite Neovim package manager:

### Using [Lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
	"https://git.k4li.de/pika/telesnip.nvim",
	dependencies = "nvim-telescope/telescope.nvim",
	opts = {
		-- ╭────────────────────────────────────────────────────────────────────────╮
		-- │ customize your custom_snippet_path (if you change the snippet_path     │
		-- │ you might break something, as this is the directory for the snippets   │
		-- │ inside the plugin folder)                                              │
		-- ╰────────────────────────────────────────────────────────────────────────╯
		-- snippet_path = "/path/to/your/snippets",
		-- custom_snippet_path = "~/.config/nvim/snippets/",
	},
	config = function(_, opts)
		require("telesnip").setup(opts)
	end,
	keys = {
		-- ─< just the standard two keybindings I configured. Be sure to make your own one, if you'd like >─
		{ "<leader>S", "<cmd>TelesnipShowSnippets<CR>", desc = "Open Snippet Picker" },
		{ "<leader>cs", "<cmd>TelesnipCustomSnippet<CR>", mode = "v", desc = "Save Custom Snippet" },
	},
}
```

## Usage

### Snippet Picker

- **Command**: `:TelesnipShowSnippets`
- **Keybinding**: (Bind this command to a key of your choice in your Neovim config)

### Save Snippet (Visual Mode)

1. Select the code you want to save as a snippet in visual mode.
2. Press the keybinding you've set up for `:TelesnipCustomSnippet` in visual mode.
3. Your selected snippet will be previewed with telescope. Type in a name and hit <Enter> to save your snippet.

## Configuration

The standard snippets directory is under the lazy folder in `~/.local/share/nvim/lazy/telesnip.nvim/lua/telesnip/snippets/`

Snippets are saved in one file, using `---` as a seperator and the first line after `---` is the name of the snippet

> [!NOTE]
> Here is the standard snippets.sh file for reference:
>
> ```bash
> # check_root
> # Check if the user is root and set sudo variable if necessary
> check_root() {
>  if [[ "${EUID}" -ne 0 ]]; then
>    if command_exists sudo; then
>      echo_binfo "User is not root. Using sudo for privileged operations."
>      _sudo="sudo"
>    else
>      echo_error "No sudo found and you're not root! Can't install packages."
>      return 1
>    fi
>  else
>    echo_binfo "Root access confirmed."
>    _sudo=""
>  fi
> }
>
> ---
> # command_exists
> # ─< Check if the given command exists silently >─────────────────────────────────────────
> command_exists() {
>  command -v "$@" >/dev/null 2>&1
> }
>
> ---
> # get_ip
> # ─< get the current ip as a 1 line >─────────────────────────────────────────────────────
> get_ip() {
>  command ip a | command grep 'inet ' | command grep -v '127.0.0.1' | command awk '{print $2}' | command cut -d/ -f1 | head -n 1
> }
>
> ---
> # echo_essentials
> # ─< Helper functions >─────────────────────────────────────────────────────────────────
> function echo_error() { echo -e "\033[0;1;31mError: \033[0;31m\t${*}\033[0m"; }
> function echo_binfo() { echo -e "\033[0;1;34mINFO: \033[0;34m\t${*}\033[0m"; }
> function echo_info() { echo -e "\033[0;1;35mInfo: \033[0;35m${*}\033[0m"; }
>
> ---
> # silentexec
> # ─< Silent execution >─────────────────────────────────────────────────────────────────
> silentexec() {
>  "$@" >/dev/null 2>&1
> }
> ```

Custom snippets (snippets you save by your own) are saved in your nvim config (under `~/.config/nvim/snippets/`), to ensure your saved snippets don't get deleted, when removin the plugin.

Every filetype can have two snippet files. One preconfigured inside the lazy.nvim directory as described earlier, and optionally one custom snippet file, inside your nvim config, which holds the custom snippets.

The paths can be configured, within the plugin configuration as described earlier.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests for new features, snippets, bug fixes, or language support.

## License

MIT License. See `LICENSE` for more information.

### ToDo

- [x] Let telescope show preconfigured snippets out of the `telesnip/snippets/<language>/` directory
- [x] Paste the snippet in directly at your cursor
- [x] Add snippets easily by selecting it in visual mode and calling the plugin as usual
- [ ] Understand the code 100%

# Showcase

```

```
