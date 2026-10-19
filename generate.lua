-- Generate a Zed theme family from folke/tokyonight.nvim.
--
--   nvim --headless -l generate.lua [tokyonight.nvim dir] [output.json]
--
-- Syntax colors are read back from the highlight groups tokyonight defines in
-- Neovim, so Zed shows exactly what nvim shows. Chrome colors are derived from
-- the same palette (see `ui`).

local root = arg[1] or vim.fn.expand("~/.local/share/nvim/site/pack/core/opt/tokyonight.nvim")
local out = arg[2] or "themes/tokyonight.json"
vim.opt.rtp:prepend(root)

local Util = require("tokyonight.util")

local styles = {
  { style = "night", name = "TokyoNight Night", appearance = "dark" },
  { style = "storm", name = "TokyoNight Storm", appearance = "dark" },
  { style = "moon", name = "TokyoNight Moon", appearance = "dark" },
  { style = "day", name = "TokyoNight Day", appearance = "light" },
}

-- Zed capture -> Neovim highlight group. Zed resolves a capture to its longest
-- dotted prefix with a theme key; nvim falls back the same way, so we only
-- name the captures whose spelling differs or whose fallback would differ.
-- stylua: ignore
local syntax = {
  ["attribute"]                 = "@attribute",
  ["attribute.jsx"]             = "@tag.attribute",
  ["boolean"]                   = "@boolean",
  ["comment"]                   = "@comment",
  ["comment.doc"]               = "@comment.documentation",
  ["comment.unused"]            = "@comment",
  ["concept"]                   = "@type",
  ["constant"]                  = "@constant",
  ["constant.builtin"]          = "@constant.builtin",
  ["constant.char"]             = "@character",
  ["constructor"]               = "@constructor",
  ["diff.delta"]                = "diffChanged",
  ["diff.minus"]                = "diffRemoved",
  ["diff.plus"]                 = "diffAdded",
  ["embedded"]                  = "@variable",
  ["emphasis"]                  = "@markup.italic",
  ["emphasis.strong"]           = "@markup.strong",
  ["enum"]                      = "@lsp.type.enum",
  ["function"]                  = "@function",
  ["function.builtin"]          = "@function.builtin",
  ["function.call"]             = "@function.call",
  ["function.decorator"]        = "@attribute",
  ["function.kwargs"]           = "@variable.parameter",
  ["function.method"]           = "@function.method",
  ["function.method.call"]      = "@function.method.call",
  ["function.special"]          = "@function.macro",
  ["hint"]                      = "LspInlayHint",
  ["keyword"]                   = "@keyword",
  ["keyword.control"]           = "@keyword.conditional",
  ["keyword.control.conditional"] = "@keyword.conditional",
  ["keyword.control.repeat"]    = "@keyword.repeat",
  ["keyword.declaration"]       = "@keyword",
  ["keyword.definition"]        = "@keyword.function",
  ["keyword.directive"]         = "@keyword.directive",
  ["keyword.exception"]         = "@keyword.exception",
  ["keyword.function"]          = "@keyword.function",
  ["keyword.import"]            = "@keyword.import",
  ["keyword.operator"]          = "@keyword.operator",
  ["keyword.preproc"]           = "@keyword.directive",
  ["keyword.return"]            = "@keyword.return",
  ["label"]                     = "@label",
  ["lifetime"]                  = "@label",
  ["link_text"]                 = "@markup.link.label",
  ["link_uri"]                  = "@markup.link.url",
  ["modifier"]                  = "@keyword.modifier",
  ["module"]                    = "@module",
  ["namespace"]                 = "@module",
  ["number"]                    = "@number",
  ["operator"]                  = "@operator",
  ["preproc"]                   = "@keyword.directive",
  ["primary"]                   = "Normal",
  ["property"]                  = "@property",
  ["punctuation"]               = "@punctuation.delimiter",
  ["punctuation.bracket"]       = "@punctuation.bracket",
  ["punctuation.bracket.jsx"]   = "@tag.delimiter.tsx",
  ["punctuation.delimiter"]     = "@punctuation.delimiter",
  ["punctuation.delimiter.jsx"] = "@tag.delimiter.tsx",
  ["punctuation.list_marker"]   = "@markup.list.markdown",
  ["punctuation.markup"]        = "@punctuation.special.markdown",
  ["punctuation.special"]       = "@punctuation.special",
  ["selector"]                  = "@tag",
  ["selector.class"]            = "@type",
  ["selector.id"]               = "@constant",
  ["selector.pseudo"]           = "@attribute",
  ["strikethrough"]             = "@markup.strikethrough",
  ["string"]                    = "@string",
  ["string.doc"]                = "@string.documentation",
  ["string.escape"]             = "@string.escape",
  ["string.regex"]              = "@string.regexp",
  ["string.special"]            = "@string.special",
  ["string.special.path"]       = "@string.special.path",
  ["string.special.symbol"]     = "@string.special.symbol",
  ["tag"]                       = "@tag",
  ["tag.component"]             = "@constructor.tsx",
  ["tag.doctype"]               = "@tag",
  ["tag.jsx"]                   = "@tag.tsx",
  ["text.jsx"]                  = "@variable",
  ["text.literal"]              = "@markup.raw.markdown_inline",
  ["title"]                     = "@markup.heading",
  ["type"]                      = "@type",
  ["type.builtin"]              = "@type.builtin",
  ["type.definition"]           = "@type.definition",
  ["type.qualifier"]            = "@type.qualifier",
  ["variable"]                  = "@variable",
  ["variable.builtin"]          = "@variable.builtin",
  ["variable.member"]           = "@variable.member",
  ["variable.other.member"]     = "@variable.member",
  ["variable.parameter"]        = "@variable.parameter",
  ["variable.special"]          = "@variable.builtin",
  ["variant"]                   = "@lsp.type.enumMember",
}

local function hex(n)
  return n and string.format("#%06x", n) or nil
end

-- Resolve a group the way the nvim treesitter highlighter does: follow links,
-- and drop trailing segments of an undefined `@capture.name`.
local function hl(name)
  while name do
    local h = vim.api.nvim_get_hl(0, { name = name, link = false })
    if next(h) then
      return h
    end
    name = name:match("^(.+)%.[^.]+$")
  end
  return {}
end

local function syntax_style(group, bg)
  local h = hl(group)
  local s = {
    color = hex(h.fg),
    -- Groups like Normal carry the editor background; only keep real fills.
    background_color = hex(h.bg) ~= bg and hex(h.bg) or nil,
    font_style = h.italic and "italic" or nil,
    font_weight = h.bold and 700 or nil,
  }
  return next(s) and s or nil
end

local function alpha(color, a)
  return color .. string.format("%02x", math.floor(a * 255 + 0.5))
end

-- Chrome. The editor and active tab share `bg`; everything around them
-- (tab bar, panels, title and status bars) sits on `bg_dark`, as nvim's
-- sidebars and statusline do. Edges are drawn with a dim blue derived from
-- `fg_gutter`, never with tokyonight's near-black `border`.
local function ui(c)
  local blend = function(color, amount, base)
    return Util.blend(color, amount, base or c.bg)
  end
  local divider = blend(c.fg_gutter, 0.6, c.bg_dark)
  local hairline = blend(c.fg_gutter, 0.35, c.bg_dark)
  local selected = blend(c.fg_gutter, 0.8)
  local transparent = "#00000000"

  local status = function(name, color, border)
    return {
      [name] = color,
      [name .. ".background"] = blend(color, 0.1),
      [name .. ".border"] = border or blend(color, 0.5),
    }
  end

  -- stylua: ignore
  local s = {
    ["background.appearance"]          = "opaque",
    ["background"]                     = c.bg_dark,
    ["border"]                         = divider,
    ["border.variant"]                 = hairline,
    ["border.focused"]                 = c.blue0,
    ["border.selected"]                = c.blue0,
    ["border.transparent"]             = transparent,
    ["border.disabled"]                = hairline,
    ["surface.background"]             = c.bg_dark,
    ["elevated_surface.background"]    = c.bg_popup,
    ["drop_target.background"]         = alpha(c.blue0, 0.25),
    ["drop_target.border"]             = c.blue0,

    ["element.background"]             = c.bg,
    ["element.hover"]                  = c.bg_highlight,
    ["element.active"]                 = c.fg_gutter,
    ["element.selected"]               = selected,
    ["element.selection_background"]   = c.bg_visual,
    ["element.disabled"]               = c.bg_dark,
    ["ghost_element.background"]       = transparent,
    ["ghost_element.hover"]            = c.bg_highlight,
    ["ghost_element.active"]           = c.fg_gutter,
    ["ghost_element.selected"]         = selected,
    ["ghost_element.disabled"]         = transparent,

    ["text"]                           = c.fg,
    ["text.muted"]                     = c.dark5,
    ["text.placeholder"]               = c.comment,
    ["text.disabled"]                  = c.dark3,
    ["text.accent"]                    = c.blue,
    ["icon"]                           = c.fg_dark,
    ["icon.muted"]                     = c.dark5,
    ["icon.disabled"]                  = c.dark3,
    ["icon.placeholder"]               = c.comment,
    ["icon.accent"]                    = c.blue,
    ["link_text.hover"]                = c.blue,
    ["debugger.accent"]                = c.red,

    ["title_bar.background"]           = c.bg_dark,
    ["title_bar.inactive_background"]  = c.bg_dark,
    ["status_bar.background"]          = c.bg_statusline,
    ["toolbar.background"]             = c.bg,
    ["tab_bar.background"]             = c.bg_dark,
    ["tab.inactive_background"]        = c.bg_dark,
    ["tab.active_background"]          = c.bg,
    ["panel.background"]               = c.bg_dark,
    ["panel.focused_border"]           = c.blue0,
    ["panel.indent_guide"]             = hairline,
    ["panel.indent_guide_active"]      = c.fg_gutter,
    ["panel.indent_guide_hover"]       = c.dark3,
    ["panel.overlay_background"]       = c.bg_dark,
    ["panel.overlay_hover"]            = c.bg_highlight,
    ["pane.focused_border"]            = transparent,
    ["pane_group.border"]              = divider,

    ["scrollbar.thumb.background"]     = alpha(c.fg_gutter, 0.6),
    ["scrollbar.thumb.hover_background"] = c.fg_gutter,
    ["scrollbar.thumb.active_background"] = c.dark3,
    ["scrollbar.thumb.border"]         = transparent,
    ["scrollbar.track.background"]     = transparent,
    ["scrollbar.track.border"]         = transparent,
    ["minimap.thumb.background"]       = alpha(c.fg_gutter, 0.35),
    ["minimap.thumb.hover_background"] = alpha(c.fg_gutter, 0.6),
    ["minimap.thumb.active_background"] = alpha(c.fg_gutter, 0.8),
    ["minimap.thumb.border"]           = transparent,

    ["search.match_background"]        = alpha(c.bg_search, 0.7),
    ["search.active_match_background"] = blend(c.orange, 0.45),

    ["editor.foreground"]              = c.fg,
    ["editor.background"]              = c.bg,
    ["editor.gutter.background"]       = c.bg,
    ["editor.subheader.background"]    = c.bg_dark,
    ["editor.active_line.background"]  = c.bg_highlight,
    ["editor.highlighted_line.background"] = c.bg_highlight,
    ["editor.debugger_active_line.background"] = blend(c.yellow, 0.15),
    ["editor.line_number"]             = c.fg_gutter,
    ["editor.active_line_number"]      = c.orange,
    ["editor.hover_line_number"]       = c.dark5,
    ["editor.invisible"]               = c.fg_gutter,
    ["editor.wrap_guide"]              = hairline,
    ["editor.active_wrap_guide"]       = divider,
    ["editor.indent_guide"]            = blend(c.fg_gutter, 0.6),
    ["editor.indent_guide_active"]     = c.fg_gutter,
    ["editor.code_lens.foreground"]    = c.comment,
    ["editor.document_highlight.read_background"] = alpha(c.fg_gutter, 0.7),
    ["editor.document_highlight.write_background"] = alpha(c.fg_gutter, 0.9),
    ["editor.document_highlight.bracket_background"] = blend(c.orange, 0.25),
    ["editor.diff_hunk.added.background"] = c.diff.add,
    ["editor.diff_hunk.added.hollow_background"] = alpha(c.git.add, 0.1),
    ["editor.diff_hunk.added.hollow_border"] = alpha(c.git.add, 0.5),
    ["editor.diff_hunk.deleted.background"] = c.diff.delete,
    ["editor.diff_hunk.deleted.hollow_background"] = alpha(c.git.delete, 0.1),
    ["editor.diff_hunk.deleted.hollow_border"] = alpha(c.git.delete, 0.5),

    ["version_control.added"]          = c.git.add,
    ["version_control.modified"]       = c.git.change,
    ["version_control.deleted"]        = c.git.delete,
    ["version_control.renamed"]        = c.blue1,
    ["version_control.conflict"]       = c.orange,
    ["version_control.ignored"]        = c.git.ignore,
    ["version_control.word_added"]     = blend(c.green2, 0.4),
    ["version_control.word_deleted"]   = blend(c.red1, 0.4),
    ["version_control.conflict_marker.ours"] = c.diff.add,
    ["version_control.conflict_marker.theirs"] = c.diff.change,

    ["terminal.background"]            = c.bg,
    ["terminal.ansi.background"]       = c.bg,
    ["terminal.foreground"]            = c.fg,
    ["terminal.bright_foreground"]     = c.fg,
    ["terminal.dim_foreground"]        = c.fg_dark,

    -- Mode indicator colors are left unset so the status bar shows plain
    -- text, as Zed's built-in themes do.
    ["vim.yank.background"]            = blend(c.orange, 0.4),
  }

  s["vim.helix_jump_label.foreground"] = c.magenta2

  for name, color in pairs({ black = "black", red = "red", green = "green", yellow = "yellow", blue = "blue", magenta = "magenta", cyan = "cyan", white = "white" }) do
    local normal, bright = c.terminal[color], c.terminal[color .. "_bright"]
    s["terminal.ansi." .. name] = normal
    s["terminal.ansi.bright_" .. name] = bright
    s["terminal.ansi.dim_" .. name] = blend(normal, 0.7)
  end

  local hint = hl("LspInlayHint")
  -- stylua: ignore
  for _, t in ipairs({
    status("error", c.error),
    status("warning", c.warning),
    status("info", c.info),
    status("success", c.green),
    status("created", c.git.add),
    status("modified", c.git.change),
    status("deleted", c.git.delete),
    status("renamed", c.blue1),
    status("conflict", c.orange),
    status("hidden", c.dark3),
    status("ignored", c.git.ignore),
    status("predictive", c.dark3),
    status("unreachable", c.dark3),
    { hint = c.hint, ["hint.background"] = hex(hint.bg), ["hint.border"] = blend(c.hint, 0.5) },
  }) do
    for k, v in pairs(t) do
      s[k] = v
    end
  end

  s.players = { { cursor = c.fg, background = c.blue, selection = c.bg_visual } }
  for _, color in ipairs({ c.magenta, c.green, c.orange, c.teal, c.yellow, c.purple, c.red }) do
    table.insert(s.players, { cursor = color, background = color, selection = alpha(color, 0.25) })
  end
  s.accents = vim.deepcopy(c.rainbow)

  return s
end

local themes = {}
for _, v in ipairs(styles) do
  vim.o.background = v.appearance
  local colors = require("tokyonight.theme").setup({ style = v.style, plugins = { all = true } })
  local style = ui(colors)
  style.syntax = {}
  for key, group in pairs(syntax) do
    style.syntax[key] = syntax_style(group, colors.bg)
  end
  table.insert(themes, { name = v.name, appearance = v.appearance, style = style })
end

local version = vim.trim(vim.fn.system({ "git", "-C", root, "rev-parse", "--short", "HEAD" }))
local family = {
  ["$schema"] = "https://zed.dev/schema/themes/v0.2.0.json",
  name = "TokyoNight",
  author = "Generated from folke/tokyonight.nvim@" .. version,
  themes = themes,
}

-- Pretty-print with sorted keys so regenerated output diffs cleanly.
local function encode(value, indent)
  indent = indent or ""
  local inner = indent .. "  "
  if type(value) ~= "table" then
    return vim.json.encode(value)
  end
  local parts = {}
  if vim.islist(value) then
    for _, item in ipairs(value) do
      table.insert(parts, inner .. encode(item, inner))
    end
    return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "]"
  end
  local keys = vim.tbl_keys(value)
  table.sort(keys, function(a, b)
    -- "$schema", "name" first; "syntax" and lists after scalar keys.
    local rank = function(k)
      return k == "$schema" and 0 or k == "name" and 1 or type(value[k]) == "table" and 3 or 2
    end
    if rank(a) ~= rank(b) then
      return rank(a) < rank(b)
    end
    return a < b
  end)
  for _, k in ipairs(keys) do
    table.insert(parts, inner .. vim.json.encode(k) .. ": " .. encode(value[k], inner))
  end
  return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
end

vim.fn.mkdir(vim.fn.fnamemodify(out, ":h"), "p")
local f = assert(io.open(out, "w"))
f:write(encode(family), "\n")
f:close()
print("wrote " .. out)
