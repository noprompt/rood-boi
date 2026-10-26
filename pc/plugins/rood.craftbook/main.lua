-- rood.craftbook: at a workshop, what the game's Combine screen can make from the
-- bag, in a small panel. Off by default: turn it on in the Lua console's Plugins
-- list (F1, Window > Lua console) or with RPC lua {action "enable", plugin
-- "rood.craftbook"}.
--
-- A template for the player state queries (pc/docs/Extensions.md "Player state"):
--   rood.game.workshop()   nil, or the workshop you stand in;
--   rood.game.craftable()  every combination it allows, each with the game's
--                          own result (MENUC's combine, run on copies);
--   rood.game.mode()       "field" when nothing else (a menu, a cutscene) is up.
-- Queries give the same read-only table until the next game vsync, so a plugin
-- can call them freely; this one still asks only twice a second and rebuilds
-- its lines only when the answer changed, so its draw function makes no garbage.

local M = {}

-- How it looks: plain data. Edit and save: the plugin reloads.
-- Two looks, as the player's UI setting. "classic" (the modern menus off): the
-- panel is drawn by the game's own frame (rood.draw.panel with {classic = true}),
-- with the game's window (d.window), its menu font and its button sprites, in the
-- game's 320 x 240 pixels from the left edge; only the typography may be upgraded
-- (Options > ui_text). "modern": the modern menus' dark panel and label font,
-- the picture's square pixels.
M.look = {
  max_lines = 6,             -- more than this: "and N more"
  title = "Craftbook",
  none = "Nothing to combine here",
  more = "and %d more",
  hint = "Menu: Combine",    -- the footer, after the button that opens the menu
  button = "triangle",
  classic = {
    x = 8, y = 42, w = 300,  -- the window's top left and width (the game's pixels)
    pad = 8, line_h = 12,    -- inner margin, one line's height (the menu font is 12 high)
    brightness = 0.5,        -- d.window: 1 a selected box, 0.5 the others
    title = { font = "menu", size = 8, color = 0xF0D070 },
    text = { font = "menu", size = 7, color = 0xFFFFFF },
    dim = { font = "menu", size = 6.5, color = 0xA0A8C0 },
  },
  modern = {
    x = 8, y = 42, w = 168, pad = 4, line_h = 9,
    panel = 0x0E1014, alpha = 0.8, edge = 0xC8A860,
    title = { font = "labels", size = 8, color = 0xE8D8A8 },
    text = { font = "labels", size = 7, color = 0xF0F0F0 },
    dim = { font = "labels", size = 6.5, color = 0xA0A0A0 },
  },
}

-- A setting of its own (Options > plugins, or rood.settings).
local show = rood.settings.define("show", {
  type = "boolean",
  label = "Show at workshops",
  help = "Lists what the Combine screen can make from your bag while you stand in a workshop.",
  default = true,
})

-- Styles are handles: made once, at load.
local styles = {}
for look, L in pairs { classic = M.look.classic, modern = M.look.modern } do
  styles[look] = { title = rood.draw.style(L.title), text = rood.draw.style(L.text), dim = rood.draw.style(L.dim) }
end

local craft = require("craft") -- the lines, a module of its own so the tests can call it

local state = { list = nil, lines = {}, title = M.look.title }

local function draw(d, view)
  if rood.game.mode() ~= "field" then return end -- not over a menu or a cutscene
  local look = view.flavour == "classic" and "classic" or "modern"
  local L, st, c = M.look[look], styles[look], M.look
  local lines = state.lines
  local shown = math.min(#lines, c.max_lines)
  local rows = 2 + math.max(shown, 1) + (#lines > shown and 1 or 0) -- the title, the lines, the footer
  local h = L.pad * 2 + rows * L.line_h
  if look == "classic" then
    d.window(L.x, L.y, L.w, h, L.brightness) -- the game's own text box: its stone body, frame and shadow
  else
    d.rect(L.x, L.y, L.w, h, L.panel, L.alpha)
    d.rect(L.x, L.y, L.w, 0.75, L.edge)
    d.rect(L.x, L.y + h - 0.75, L.w, 0.75, L.edge)
  end
  local x, y, w = L.x + L.pad, L.y + L.pad, L.w - 2 * L.pad
  d.fit(st.title, state.title, x, y, w, L.line_h)
  if #lines == 0 then
    d.fit(st.dim, c.none, x, y + L.line_h, w, L.line_h)
  end
  for i = 1, shown do
    d.fit(st.text, lines[i], x, y + i * L.line_h, w, L.line_h)
  end
  if #lines > shown then
    d.fit(st.dim, state.more, x, y + (shown + 1) * L.line_h, w, L.line_h)
  end
  -- the footer: the button that opens the menu, as the game draws it (the pad's own icon)
  local fy = y + (rows - 1) * L.line_h
  local gw = d.glyph(c.button, x, fy + L.line_h / 2, L.line_h - 2, st.dim)
  d.fit(st.dim, c.hint, x + (gw > 0 and gw + 2 or 0), fy, w, L.line_h)
end

-- Twice a second: the workshop and what it can make; the panel set while in one.
local drawing = false
local function refresh()
  local workshop = rood.settings.get(show) and rood.game.workshop()
  if not workshop then
    if drawing then rood.draw.panel(nil) end
    drawing, state.list = false, nil
    return
  end
  local list = rood.game.craftable()
  if list ~= state.list then
    state.list = list
    state.lines = craft.lines(list)
    state.title = M.look.title .. ": " .. workshop.name
    state.more = string.format(M.look.more, #state.lines - M.look.max_lines)
  end
  if not drawing then rood.draw.panel(draw, { classic = true }) end
  drawing = true
end

rood.timer.every(0.5, refresh, { clock = "real" })
refresh()

return M
