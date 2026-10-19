# TokyoNight for Zed, generated from tokyonight.nvim

`generate.lua` loads [folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim)
in headless Neovim, applies each style (night, storm, moon, day), and reads the
resulting highlight groups back out. Syntax colors are therefore the ones nvim
shows, not a hand copy:

- Each Zed capture name (`function.method`, `string.special.symbol`, …) maps to
  the treesitter group nvim uses for the same thing (`syntax` table). Both
  editors fall back along the dotted name, so only differing spellings are listed.
- Groups are resolved through links and nvim's own fallback, so italics and
  weights (italic keywords and comments) carry over.

The chrome is derived from the same palette (`ui` in `generate.lua`):

- The editor and active tab share `bg`. Everything around them (tab bar,
  panels, title and status bars) sits on `bg_dark`, like nvim's sidebars and
  statusline.
- Dividers are a dim blue mixed from `fg_gutter`, not tokyonight's
  near-black `border`.
- The scrollbar track has no border. Selection, search, diff, git, diagnostic
  and terminal colors come from the nvim palette (`bg_visual`, `bg_search`,
  `git.*`, `diff.*`, `terminal.*`).

## Use

    just install     # regenerate and copy to ~/.config/zed/themes

Then pick a theme in Zed: `TokyoNight Night`, `Storm`, `Moon` or `Day`.

Set `TOKYONIGHT=/path/to/tokyonight.nvim` to generate from another checkout.
By default the generator uses the copy nvim loads.

## License

Apache-2.0, as is [tokyonight.nvim](https://github.com/folke/tokyonight.nvim), whose palette and highlight groups this generates from.
