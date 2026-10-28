-- rood.classic (shipped, on): the classic look (ui_menus 0) drawn from Lua (pc/docs/Extensions.md,
-- "The classic look in Lua"; plan pc/docs/plans/2026-10-20-classic-ui-in-lua.md).
--
-- The kinds: the timing word (status), the chain count (chain) and the status display's HP / MP / RISK
-- gauges with their digits and labels (gauges), and Ashley's body/damage silhouette (figure).
-- The status carousel (status_icons), BATTLE MODE notice (battle_mode), and ability_icons are Lua too, and so
-- are the buffs (buff: WEAPON HUMAN +1), the numbers over the actors (damage) and the words over them (actor_word:
-- MISS, the ailments' and buffs' words), quads as the game builds them, the time attack's timer (timer) and the
-- emote balloons over the actors (emote).
-- Ability groups leave pc_weapon_slots_label's weapon-mode names/markers and side effects in C.
-- Each draw function below is a copy of the game's own, made of the game's own pieces (d.text_raw is
-- its raw printer, d.value its digits, d.bar its gauge), so by default it emits exactly the game's
-- packets: the parity gate
-- (pc/tests/classic_parity.py) compares them every frame. What this file may change is the look the
-- classic rule allows: typography (how ui_text sets the game's glyphs: `typeset`, `typography`) and
-- 16:9 placement (`place`); each deliberate difference is named in `look.overrides` (the gate's
-- waivers, pc/tests/classic/waivers.toml, must list the same).
--
-- Edit `look` and save: the running game reloads this file in about half a second. To have something
-- to look at, in the Lua console (F1, Window > Lua console), in the field with the modern UI off:
--   rood.dev.show("status", { timing = "success", variant = 5 })   WELL TIMED!, held until rood.dev.clear()
--   rood.dev.show("status", { timing = "too_slow" })               TOO SLOW!
--   rood.dev.show("chain", { count = 3 })                           3 CHAINS
--   rood.dev.show("buff", { slot = "WEAPON", stat = "HUMAN", value = 1 })  WEAPON HUMAN +1
--   rood.dev.show("damage", { value = 57 })                         57 over Ashley
-- (the gauges are up whenever the field is: M.look.gauges.place.dx = 6 moves them at the next frame)
-- The REPL (pc/tools/rood_repl.py --plugin rood.classic) has this file's module as M: M.look.typeset.margin = 4
-- shows on the held word at the next frame; saving the file brings the file's values back.
-- Turned off (the Lua console's Plugins list), broken, or a kind's hud_classic_<kind> setting off: the
-- game draws them itself (the fallback, typography from ui_text's defaults).
local M = { draw = {} }
local S = rood.settings.get

local function make_look()
  return {
    -- The timing word (BATTLE.PRG func_800958A4, the label loop's kind 4): the game's own strings ('$'
    -- centres the word on x; two-word phrases are padded with the font's narrow blanks), colours (PS1
    -- colour words: 0xBBGGRR, 0x80 full) and slide (pixels left of its place at ages 0..3 coming in,
    -- and from `slide_out` on going out, the steps backwards).
    status = {
      place = { anchor = "left", dx = 0, dy = 0 }, -- 16:9: at the screen's left edge (the game's hook's anchor)
      words = { too_fast = "$TOO   FAST!", fast = "$FAST!", slow = "$SLOW!", too_slow = "$TOO   SLOW!" },
      success = { "$COOL!", "$GOOD!", "$EXCELLENT!", "$RIGHT   ON!", "$PERFECT!", "$WELL   TIMED!", "$NICE!",
                  "$GREAT!" },
      colours = { too_fast = 0x808000, fast = 0x608020, success = 0x408040, slow = 0x208060, too_slow = 0x008080 },
      slide = { 64, 16, 4, 1 },
      slide_out = 42,
    },
    -- The chain count (func_80095A4C, kind 5): "3 CHAINS" ("1 CHAIN"), slid in only for the first.
    chain = {
      place = { anchor = "left", dx = 0, dy = 0 },
      one = "$1 CHAIN",
      many = "$%d CHAINS",
      colour = 0x1040A0,
      slide = { 64, 16, 4, 1 },
      slide_out = 87,
    },
    -- The status display's gauges (5BF94.c func_800CA2DC's _renderStatBar calls): HP, MP and RISK, each a
    -- bar, its digits (the current value large, the maximum small with a separator) and its label; with no
    -- risk, RISK ZERO. The game's places (D_800EBBDC, D_800EBBEC: x, y before the display's slide), labels
    -- (the field UI page's HP, MP, RISK: D_800EBBFC, D_800EBC00) and the steps between them as data; the
    -- slots (bytes from vs_scratch.unk4) the game links them into.
    gauges = {
      place = { anchor = "left", dx = 0, dy = 0 }, -- 16:9: the panel's left edge
      pools = {
        { pool = "hp", bar = { 10, 18 }, label = { 10, 10 }, sprite = { page_x = 768, page_y = 0, bits = 4,
          u = 144, v = 0, w = 16, h = 9, clut_x = 864, clut_y = 223 } },
        { pool = "mp", bar = { 80, 18 }, label = { 80, 10 }, sprite = { page_x = 768, page_y = 0, bits = 4,
          u = 160, v = 0, w = 18, h = 9, clut_x = 864, clut_y = 223 } },
        { pool = "risk", bar = { 10, 22 }, label = { 10, 26 }, sprite = { page_x = 768, page_y = 0, bits = 4,
          u = 180, v = 0, w = 26, h = 9, clut_x = 864, clut_y = 223 } },
      },
      -- (steps as the game writes them: packed x | y << 16, added to its packed place: x's carry reaches y)
      maximum = 56 | (-8 << 16),        -- the small maximum's rightmost digit from the bar's place
      separator = 0xFFF9 | (0xFFFE << 16), -- the large current value's from the pen the maximum leaves
      risk_value = 54 | (3 << 16),      -- RISK's value (no maximum) from its bar's place
      digit_step = 5,                   -- the small digits' advance (vs_battle_renderValue: 5 + its font)
      risk_max = 100,
      zero = { text = "RISK  ZERO", x = 12, y = 22, colour = 0x808080 },
      layers = { bars = -12, digits = -16 },
    },
    -- Ashley's silhouette: D_800EBCEC / D_800EBD14 / D_800EBD3C, in the game's limb order.
    -- Each row is {dx, dy, width, height, u, v}; stance 0 then 1. Colours are D_800EBC54,
    -- indexed by the game's read-only condition (critical, damaged, wounded, good, excellent).
    figure = {
      place = { anchor = "left", x = 8, y = 184, dx = 0, dy = 0 }, layer = -4,
      colours = { 0x180058, 0x004070, 0x087078, 0x186820, 0x687018 },
      stances = {
        { {8,8,12,20,16,184}, {24,8,12,18,32,160}, {16,0,12,12,0,160},
          {16,8,12,14,0,172}, {8,16,28,24,44,160} },
        { {0,8,18,20,12,160}, {24,8,16,22,32,184}, {16,0,12,12,0,160},
          {16,8,12,14,0,172}, {8,16,28,24,44,160} },
      },
      sprite = { page_x = 768, page_y = 0, bits = 4, clut_x = 832, clut_y = 223 },
    },
    ability_icons = {
      place = { anchor = "centre", dx = 0, dy = 0 }, layer = "unk8", right_x = 160,
      -- marker x/y, label x/y/w/h/u/v; IDs 0..3 right, 4..7 left.
      labels = {
        {77,101,82,99,47,9,52,101}, {53,115,-2,113,58,9,100,101},
        {87,113,92,111,52,9,0,101}, {63,127,7,125,58,9,160,101},
        {89,101,94,99,34,9,0,113}, {70,115,27,112,57,9,152,113},
        {98,113,103,111,45,9,104,113}, {80,127,16,124,67,9,36,113},
      },
      marker = { w = 6, h = 6, u = 192, v = 128 },
      face_xy = { 0x640041, 0x6D0038, 0x6D004A, 0x760041 },
      face = { size = 16, u_step = 16, v = 128 },
      cross = { x = 72, y = 102, w = 30, h = 30, u = 184, v = 160 },
      label_sprite = { page_x = 448, page_y = 256, bits = 4, clut_x = 976, clut_y = 220 },
      button_sprite = { page_x = 768, page_y = 0, bits = 4, clut_x = 944, clut_y = 223 },
      full_colour = 0x808080, semi_alpha = 0.5,
      -- C decides eligibility; its codes select independent presentation styles.
      availability = {
        [0x140] = { colour = 0x404040, alpha = 0.5 },
        [0x180] = { colour = 0x808080, alpha = 0.5 },
      },
    },
    battle_mode = {
      place = { anchor = "right", dx = 0, dy = 0 }, layer = -12,
      x = 236, y = -4, step_y = 3, colour = 0x404040, alpha = 0.5,
      sprite = { page_x = 448, page_y = 256, bits = 4, u = 64, v = 0,
        w = 73, h = 10, clut_x = 976, clut_y = 220 },
    },
    -- func_800C9CB4: clipped carousel cells and the count/selection indicators.
    status_icons = {
      place = { anchor = "left", dx = 0, dy = 0 }, layers = { icons = -4, indicators = -8 },
      x = 160, y = 8, cell = 16, supplemental_h = 8,
      supplemental_w = 8, supplemental_stride = 8,
      supplemental_alignment = 8, -- positive power of two: atlas clipping masks
      texels = { 0x1010,0x1020,0x1030,0x1040,0x1050,0x1060,0x1080,0x1090,
        0x10A0,0x10B0,0x10C0,0x10D0,0x10E0,0x10F0,0x2000,0x2010,
        0x30B8,0x30B8,0x30B8,0x30B8,0x3098,0x3098,0x3098,0x3098,
        0x30C8,0x30C8,0x30C8,0x30C8,0x30A8,0x30A8,0x30A8,0x30A8 },
      alternate_clut = 0x0F0F906A, cluts = { 0x37F8, 0x37F9 },
      supplemental_uv = 0x3068, supplemental_clut = 0x37FF,
      indicator = { x = 148, y = 8, step = 3, row_step = 3, size = 4,
        columns = 8, -- positive power of two; selection deliberately tests this bit (not row division)
        strip_padding = 1, strip_from = 3,
        dot_uv = 0x0C1A, strip_uv = 0x0C00, clut = 0x37F4 },
      sprite = { page_x = 768, page_y = 0, bits = 4, bgr = 0x808080 },
    },
    -- An equipment's class or affinity change (2842C.c func_8009695C, the label loop's kind 6): WEAPON HUMAN +1,
    -- textured quads of the field UI page at 8, 172 less the record's rise (10 for each buff shown after it).
    -- The words' texels (D_80069144 by equipment, D_8006917C by class / affinity: u, v, w, h), the colour
    -- words (a gain, a loss), the gaps between the pieces, the sign's and the small digits' cells.
    buff = {
      place = { anchor = "left", dx = 0, dy = 0 }, layer = 8,
      slots = { WEAPON = { 72, 160, 32, 8 }, SHIELD = { 76, 168, 28, 8 }, ["R.ARM"] = { 78, 176, 26, 8 },
        ["L.ARM"] = { 78, 184, 26, 8 }, HEAD = { 82, 192, 22, 8 }, BODY = { 82, 200, 22, 8 },
        LEGS = { 82, 208, 22, 8 } },
      stats = { HUMAN = { 104, 160, 28, 8 }, BEAST = { 104, 168, 26, 8 }, UNDEAD = { 104, 176, 30, 8 },
        PHANTOM = { 104, 184, 36, 8 }, DRAGON = { 104, 192, 32, 8 }, EVIL = { 104, 200, 18, 8 },
        PHYSICS = { 144, 160, 30, 8 }, AIR = { 144, 168, 14, 8 }, FIRE = { 144, 176, 18, 8 },
        EARTH = { 144, 184, 26, 8 }, WATER = { 144, 192, 26, 8 }, LIGHT = { 144, 200, 22, 8 },
        DARKNESS = { 144, 208, 36, 8 } },
      colours = { gain = 0x804000, loss = 0x004080 },
      gap = 2,                                                       -- after each word
      sign = { dy = -1, w = 8, h = 8, gain_u = 128, loss_u = 120, v = 208, after = 2 },
      digits = { dy = -1, w = 6, h = 10, step = 5, u_step = 6, v = 0 },
      words = { page_x = 768, page_y = 0, bits = 4, clut_x = 848, clut_y = 223 },
      figures = { page_x = 768, page_y = 0, bits = 4, clut_x = 832, clut_y = 223 },
    },
    -- A number over an actor (func_80094B0C, kind 1): damage, healing, MP; a stat's change (func_80094E18:
    -- its icon of the combat labels (D_80068FAC by D_800E861C: u, v, w), its sign, the digits, drifting
    -- by half the age). The large digits' cells, colour words by pool (a loss, a gain), the bounce by frame
    -- (a gain from frame 0, a loss from frame 4; each digit to the left half the one before).
    damage = {
      place = { anchor = "centre", dx = 0, dy = 0 }, layer = -20,
      colours = { hp = { loss = 0x808080, gain = 0x008000 }, mp = { loss = 0x800080, gain = 0x808000 },
        stat = { loss = 0x808080, gain = 0x808080 } },
      bounce = { 0, -6, -12, -14, -16, -10, -5, -1, 0, -3, -6, -7, -8, -5, -3, -1, 0, -2, -1, 0 },
      loss_frame = 4, last_frame = 15,
      digits = { w = 8, h = 12, step = 6, u = 64, u_step = 8, v = 0, half = 6, centre = 3, clip = 328 },
      figures = { page_x = 768, page_y = 0, bits = 4, clut_x = 832, clut_y = 223 },
      stat = {
        icons = { { 102, 76, 16 }, { 220, 100, 18 }, { 0, 64, 24 }, { 24, 64, 20 }, { 44, 64, 24 }, { 152, 52, 26 } },
        h = 12, half = 6, padding = 12, -- (its width: the digits', the icon's and this, halved)
        icon = { page_x = 448, page_y = 256, bits = 4, clut_x = 976, clut_y = 220, raw = true },
        sign = { gap = 4, dy = -5, w = 8, h = 10, gain_u = 162, loss_u = 154, v = 76,
          page_x = 768, page_y = 0, bits = 4, clut_x = 864, clut_y = 223, raw = true },
      },
    },
    -- A word over an actor (2842C.c's label loop, slot -20), the draw the game chose. MISS (func_8009506C): the
    -- info capitals M, I, S, S (D_800E8640: u, v, w; 10 texels high) from 16 pixels left of its place, squashed
    -- open over its first ages and shut over its last (D_800E8634: half its height by step), raw and half
    -- blended. A combat label (func_80095258): the ailments' and buffs' words, one or two pieces of the combat
    -- labels' page (D_800690B4: its colour, then its pieces; `pieces` is D_80068FAC: u, v, w; 12 high), centred
    -- on its place, sliding in from the right and out to the left (`slide`, by its first and last ages), its
    -- colour (D_80069134: r, g, b) faded in (`fade` / 32), held at half plus 96 (`lit`), then half; a lowered
    -- stat's word (`lowered`) does not slide, takes the first colour and shows the arrow (func_800957D0)
    -- from age 15, its cell stepping right to the fourth.
    actor_word = {
      place = { anchor = "centre", dx = 0, dy = 0 }, layer = -20,
      enter = 4, leave = 27, life = 30,                -- (ages: the first held step, the first leaving one, 0 at)
      miss = { dx = -16, letters = { { 100, 86, 11 }, { 70, 86, 4 }, { 160, 86, 9 }, { 160, 86, 9 } }, h = 10,
        squash = { 1, 2, 4, 5, 5 }, alpha = 0.5,
        sprite = { page_x = 768, page_y = 0, bits = 4, clut_x = 864, clut_y = 223, raw = true } },
      labels = { { 0, 31 }, { 0, 29, 27 }, { 0, 30, 27 }, { 0, 28, 26 }, { 0, 32, 27 }, { 0, 1, 5 }, { 1, 1, 4 },
        { 0, 2, 5 }, { 1, 2, 4 }, { 0, 3, 5 }, { 1, 3, 4 }, { 2, 7 }, { 2, 8 }, { 2, 9 }, { 2, 10 }, { 2, 11 },
        { 2, 12 }, { 3, 13 }, { 3, 14 }, { 0, 15, 5 }, { 1, 15, 4 }, { 2, 16, 19 }, { 2, 16, 20 }, { 2, 16, 21 },
        { 2, 16, 22 }, { 2, 17, 19 }, { 2, 17, 20 }, { 2, 17, 21 }, { 2, 17, 22 } },
      pieces = { { 0, 64, 36 }, { 0, 64, 24 }, { 24, 64, 20 }, { 44, 64, 24 }, { 224, 64, 16 }, { 212, 76, 32 },
        { 150, 64, 26 }, { 68, 64, 40 }, { 108, 64, 30 }, { 138, 64, 50 }, { 188, 64, 36 }, { 0, 76, 52 },
        { 52, 76, 30 }, { 144, 88, 58 }, { 120, 76, 60 }, { 180, 76, 30 }, { 136, 88, 8 }, { 104, 88, 32 },
        { 76, 88, 40 }, { 0, 88, 16 }, { 20, 88, 20 }, { 40, 88, 30 }, { 72, 88, 32 }, { 102, 76, 16 },
        { 220, 100, 18 }, { 152, 52, 26 }, { 182, 40, 30 }, { 214, 40, 24 }, { 152, 52, 28 }, { 180, 52, 40 },
        { 220, 52, 30 }, { 108, 64, 30 }, { 216, 28, 28 } },
      colours = { { 208, 208, 208 }, { 64, 192, 255 }, { 255, 208, 48 }, { 160, 224, 96 } },
      h = 12, half = 6, alpha = 0.5,
      slide = { 32, 14, 6, 2 }, fade = { 5, 9, 13, 15 }, lit_until = 6, lit_from = 25, lit = 96,
      fading = { page_x = 448, page_y = 256, bits = 4, abr = 1, clut_x = 960, clut_y = 220 },
      held = { page_x = 448, page_y = 256, bits = 4, clut_x = 976, clut_y = 220 },
      arrow = { from = 15, steps = 4, dx = -8, dy = -5, w = 16, h = 10, u = 64, u_step = 16, v = 48,
        sprite = { page_x = 448, page_y = 256, bits = 4, clut_x = 992, clut_y = 220, raw = true } },
    },
    -- The time attack's timer (5BF94.c _renderTimer, while the lower screen shows it): the game's string
    -- (mm:ss:hh, its digits the game's) in the info capitals at 128, 200, grey, slot -4.
    timer = { place = { anchor = "centre", dx = 0, dy = 0 }, layer = -4, x = 128, y = 200, colour = 0x808080 },
    -- An emote over an actor (2842C.c func_80095C18), linked into its actor's depth slot (the layer the
    -- kind's own). The balloon (D_80068F04's corners and D_80068F64's texels by side: 0, 1 the speech balloon
    -- facing either way, 2, 3 the shout, 4, 5 the surprise strokes), then its marks from the place by side
    -- (D_80068F94, packed as the game adds them): one to three dots, '!' in the shout, the heart; '?' alone
    -- sets its own page. An off-screen actor's arrow (func_8009651C, slot -16): eight points about the clamped
    -- place, turned by the direction (1 left, 2 right, 4 up, 8 down and their pairs). (A far actor's sprite,
    -- the kind's bit 8, stays the game's: the gate has no scene that shows one.)
    emote = {
      place = { anchor = "centre", dx = 0, dy = 0 },
      corners = { { -6, -22, 18, -22, -6, 1, 18, 1 }, { -17, -22, 7, -22, -17, 1, 7, 1 },
        { -10, -29, 20, -29, -10, 1, 20, 1 }, { -19, -29, 9, -29, -19, 1, 9, 1 },
        { -9, -16, 11, -16, -9, -3, 11, -3 }, { -10, -16, 10, -16, -10, -3, 10, -3 } },
      uvs = { { 64, 16, 88, 16, 64, 39, 88, 39 }, { 87, 16, 63, 16, 87, 39, 63, 39 },
        { 121, 17, 151, 17, 121, 47, 151, 47 }, { 150, 17, 120, 17, 150, 47, 120, 47 },
        { 160, 17, 180, 17, 160, 30, 180, 30 }, { 179, 17, 159, 17, 179, 30, 159, 30 } },
      marks = { -983042, -983054, -1376256, -1310727, -720893, -720893 },
      balloon = { page_x = 448, page_y = 256, bits = 4, clut_x = 992, clut_y = 220, bgr = 0x808080 },
      dot = { step = 6, sprite = { page_x = 448, page_y = 256, bits = 4, u = 90, v = 18, w = 5, h = 5,
        clut_x = 992, clut_y = 220, bgr = 0x808080, set_page = false } },
      shout = { page_x = 448, page_y = 256, bits = 4, u = 152, v = 17, w = 7, h = 12, clut_x = 992, clut_y = 220,
        bgr = 0x808080, set_page = false },
      heart = { offset = 2 | (-3 << 16), sprite = { page_x = 448, page_y = 256, bits = 4, u = 152, v = 32, w = 16,
        h = 16, clut_x = 992, clut_y = 220, bgr = 0x808080, set_page = false } },
      question = { offset = -22 << 16, sprite = { page_x = 448, page_y = 256, bits = 4, u = 183, v = 17, w = 7, h = 12,
        clut_x = 992, clut_y = 220, bgr = 0x808080 } },
      arrow = { dx = { -8, 0, 7, 10, 7, 0, -8, -11 }, dy = { -8, -11, -8, 0, 7, 10, 7, 0 },
        directions = { [4] = 0, [6] = 1, [2] = 2, [10] = 3, [8] = 4, [9] = 5, [1] = 6, [5] = 7 },
        quad = { page_x = 768, page_y = 0, bits = 4, clut_x = 976, clut_y = 223, raw = true,
          corners = { 0, 0, 0, 0, 0, 0, 0, 0 }, uvs = { 48, 48, 63, 48, 48, 63, 63, 63 } } },
    },
    -- How ui_text sets both (with ui_text font; the packets stay the game's): the status style,
    -- typeset as one word centred where the game centres it.
    typeset = {
      style = "status",
      blanks = "one",        -- a run of the game's narrow blanks is one space ("each": a space for each)
      keep_on_screen = true, -- moved only as far as it takes to stay on the screen (WELL TIMED! starts at x 5)
      screen_w = 320,        -- the field's screen (16:9 anchors the HUD at the window's edges: the same holds)
      margin = S("ui_text_edge_margin"),   -- pixels beyond the outline kept from the edges
      word_space = S("ui_text_word_space"), -- the font's space times this
    },
    -- ui_text's styles for this run (rood.hud.typography: font, size, stroke, tracking, stretch, slant,
    -- embolden, ...; over the ui_text_<style>_* settings; empty: the settings'), and its tunables:
    typography = {
      status = {},
      -- the gauges' digits: the font's old-style figures (3 4 5 7 9 descend) rise together into the room
      -- above them, by this much of what their deepest descender lacks, before any is squeezed (playtest fix
      -- 1d2f20c5: 1, all it takes; 0 the old squeeze that flattened 5s and 7s)
      digits = { descender_lift = S("ui_text_descender_lift") },
    },
    -- The deliberate differences from the game's packets, per kind (the parity gate's waivers):
    -- typography changes no packet (ui_text restyles at raster time); a place with dx, dy or another
    -- anchor would be "place".
    -- (the buffs' and the numbers' digits are the digits style's: look.typography.digits sets them too)
    overrides = { status = { "typography" }, chain = { "typography" }, gauges = { "typography" },
      buff = { "typography" }, damage = { "typography" } },
  }
end

local SETTINGS = { "ui_text_edge_margin", "ui_text_word_space", "ui_text_descender_lift" }
local look
local chain_text = {} -- "$3 CHAINS" by count, made once (no string per frame)

local function refresh()
  look = make_look()
  M.look = look
  chain_text = {}
  for style, fields in pairs(look.typography) do
    rood.hud.typography(style, next(fields) and fields or nil)
  end
end
M.refresh = refresh
refresh()
for _, key in ipairs(SETTINGS) do rood.settings.on_change(key, refresh) end

-- x moved by a slide table: in at ages 0..3, out from `out` on (the game's steps backwards).
local function slid(x, age, slide, out, coming_in)
  if coming_in and age < 4 then return x - slide[age + 1] end
  if age >= out then
    local step = out + 3 - age
    if step >= 0 and step < 4 then return x - slide[step + 1] end
  end
  return x
end

-- status: func_800958A4 (x, y: its call's 44, 48)
M.draw.status = function(e, d)
  local s = look.status
  local text = e.timing == "success" and s.success[(e.variant or 0) + 1] or s.words[e.timing]
  if not text then return end
  d.anchor(s.place.anchor)
  local x = slid(e.call_x, e.age, s.slide, s.slide_out, true)
  d.text_raw(text, x + s.place.dx, e.call_y + s.place.dy, s.colours[e.timing], look.typeset)
end

-- chain: func_80095A4C (x, y: 44, 64)
M.draw.chain = function(e, d)
  local c = look.chain
  local text = chain_text[e.value]
  if not text then
    text = e.value == 1 and c.one or string.format(c.many, e.value)
    chain_text[e.value] = text
  end
  d.anchor(c.place.anchor)
  local x = slid(e.call_x, e.age, c.slide, c.slide_out, e.value == 1)
  d.text_raw(text, x + c.place.dx, e.call_y + c.place.dy, c.colour, look.typeset)
end

-- gauges: func_800CA2DC's _renderStatBar(0, 1, 2) and RISK ZERO. The game links each packet at the head of
-- its slot, so a slot draws in the reverse of the game's calls: the commands below go in drawing order
-- (RISK ZERO, then RISK, MP, HP: each its label, value, separator, maximum, bar).
local xy = rood.draw.xy
local function digits(v)
  local n = 1
  while v >= 10 do v, n = v // 10, n + 1 end
  return n
end
local function gauge(d, g, i, current, max, dy)
  local p = g.pools[i]
  if max == 0 then return end -- (the game draws nothing for a pool with no maximum)
  local bx, by = xy(p.bar[1] + g.place.dx, p.bar[2] + g.place.dy, dy << 16)
  local mx, my, sx, sy, cx, cy
  if i == 3 then
    cx, cy = xy(bx, by, g.risk_value)
  else
    mx, my = xy(bx, by, g.maximum)
    sx, sy = xy(mx, my, -digits(max) * g.digit_step) -- (the pen the small digits leave)
    cx, cy = xy(sx, sy, g.separator)
  end
  local lx, ly = xy(p.label[1] + g.place.dx, p.label[2] + g.place.dy, dy << 16)
  d.layer(g.layers.bars)
  d.sprite(lx, ly, p.sprite)
  d.layer(g.layers.digits)
  d.value(1, cx, cy, current)
  if i ~= 3 then
    d.layer(g.layers.bars)
    d.digit(2, sx, sy, 0)
    d.layer(g.layers.digits)
    d.value(0, mx, my, max)
  end
  d.layer(g.layers.bars)
  d.bar(bx, by, current, max, p.pool)
end
M.draw.gauges = function(e, d)
  local g = look.gauges
  local dy = -(e.slide >> 16) -- (the display slides up 8 pixels a step)
  d.anchor(g.place.anchor)
  if e.risk == 0 then
    d.layer(g.layers.bars)
    d.text_raw(g.zero.text, g.zero.x + g.place.dx, g.zero.y + g.place.dy + dy, g.zero.colour)
  else
    gauge(d, g, 3, e.risk, g.risk_max, dy)
  end
  gauge(d, g, 2, e.mp, e.max_mp, dy)
  gauge(d, g, 1, e.hp, e.max_hp, dy)
end

-- Commands are in drawing order: the game's last limb is at the head of the slot.
local limb_fields = { "limb_0_status", "limb_1_status", "limb_2_status", "limb_3_status", "limb_4_status" }
M.draw.figure = function(e, d)
  local f = look.figure
  d.anchor(f.place.anchor)
  d.layer(f.layer)
  for i = 5, 1, -1 do
    local p = f.stances[e.stance + 1][i]
    local s = f.sprite -- reused descriptor: draw copies its values, no allocation each frame
    s.w, s.h, s.u, s.v, s.bgr = p[3], p[4], p[5], p[6], f.colours[e[limb_fields[i]] + 1]
    local x, y = xy(f.place.x + f.place.dx, f.place.y + f.place.dy, p[1] | (p[2] << 16))
    d.sprite(x, y, s)
  end
end

-- Drawing order, not allocation order: reverse the game's calls within each OT slot.
local function status_sprite(d, s, x, y, w, h, uv, clut, set_page)
  local p = s.sprite
  p.set_page = set_page ~= false
  p.w, p.h, p.u, p.v = w, h, uv & 255, (uv >> 8) & 255
  p.clut_x, p.clut_y = (clut & 63) * 16, clut >> 6
  d.sprite(x + s.place.dx, y + s.place.dy, p)
end
local function status_cell(d, s, id, offset, side)
  if id == 255 then return end
  local uv, x, w = s.texels[id + 1], s.x + side * s.cell, s.cell
  if offset < 0 then uv, w = uv - offset, w + offset
  else x, w = x + offset, w - offset end
  local clut = s.cluts[((s.alternate_clut >> id) & 1) + 1]
  -- A clipped buff/debuff also has a stat glyph; emit it first (C links it last).
  local width, alignment = s.supplemental_w, s.supplemental_alignment
  if (id & 16) ~= 0 and (x & alignment) == 0 then
    local sx, sw = x, w
    local suv = (id & 3) * s.supplemental_stride + s.supplemental_uv
    if sw > width then
      if (sx & (alignment - 1)) ~= 0 then sx, sw = sx + width, sw - width
      else sx, sw = sx - width + sw, width end
    else suv = suv + width - sw end
    status_sprite(d, s, sx, s.y, sw, s.supplemental_h, suv, s.supplemental_clut)
  end
  status_sprite(d, s, x, s.y, w, s.cell, uv, clut)
end
M.draw.status_icons = function(e, d)
  local s, o = look.status_icons, e.offset
  d.anchor(s.place.anchor)
  d.layer(s.layers.icons)
  if e.slide == 0 then
    status_cell(d, s, e.previous, o, 0)
    status_cell(d, s, e.current, o + s.cell, 0)
    status_cell(d, s, e.current, o, 1)
    status_cell(d, s, e.next, o + s.cell, 1)
  end
  d.layer(s.layers.indicators)
  local p = s.indicator
  local x, y = xy(p.x, p.y, -e.slide)
  if e.count < p.strip_from then
    for i = e.count - 1, 0, -1 do
      status_sprite(d, s, x + i * p.step, y, p.size, p.size, p.dot_uv, p.clut)
    end
  else
    status_sprite(d, s, x, y, math.min(e.count, p.columns) * p.step + p.strip_padding, p.size, p.strip_uv, p.clut)
    if e.count > p.columns then
      status_sprite(d, s, x, y + p.row_step, (e.count - p.columns) * p.step + p.strip_padding, p.size, p.strip_uv, p.clut, false)
    end
    if e.selected ~= 255 then
      status_sprite(d, s, x + (e.selected & (p.columns - 1)) * p.step,
        y + ((e.selected & p.columns) == 0 and 0 or p.row_step), p.size, p.size, p.dot_uv, p.clut, false)
    end
  end
end

M.draw.battle_mode = function(e, d)
  local b = look.battle_mode
  d.anchor(b.place.anchor)
  d.layer(b.layer)
  -- The game adds sine>>5 to the packed BGR word, NOT to every channel.
  b.sprite.bgr = (b.colour + e.pulse) & 0xFFFFFF
  local x, y = xy(b.x, b.y + e.step * b.step_y, -e.slide)
  d.sprite(x + b.place.dx, y + b.place.dy, b.sprite, nil, b.alpha)
end

local function ability_sprite(d, a, sprite, x, y, w, h, u, v, colour, alpha)
  sprite.w, sprite.h, sprite.u, sprite.v, sprite.bgr = w, h, u, v, colour
  d.sprite(x + a.place.dx, y + a.place.dy, sprite, nil, alpha)
end
M.draw.ability_icons = function(e, d)
  local a, id, offset = look.ability_icons, e.group, e.offset
  d.anchor(a.place.anchor)
  d.layer(a.layer)
  if id == 8 then
    local c = a.cross
    local x, y = xy(c.x + offset, c.y, 0) -- C masks x; no carry into y
    ability_sprite(d, a, a.button_sprite, x, y, c.w, c.h, c.u, c.v, a.full_colour, a.semi_alpha)
    return
  end
  local xbase = id < 4 and a.right_x - offset or offset
  if id < 4 then
    local f, index = a.face, 4 - id
    local x, y = xy(0, 0, a.face_xy[index] + xbase) -- unlike labels, packed carry is intentional
    ability_sprite(d, a, a.button_sprite, x, y, f.size, f.size, (index - 1) * f.u_step, f.v, a.full_colour, 1)
  end
  if e.availability ~= 0 then
    local p, m = a.labels[id + 1], a.marker
    local style = a.availability[e.availability]
    local colour, alpha = style.colour, style.alpha
    local x, y = xy(xbase + p[3], p[4], 0)
    ability_sprite(d, a, a.label_sprite, x, y, p[5], p[6], p[7], p[8], colour, alpha)
    x, y = xy(xbase + p[1], p[2], 0)
    ability_sprite(d, a, a.label_sprite, x, y, m.w, m.h, m.u, m.v, colour, alpha)
  end
end

-- buff: func_8009695C (x, y: its call's 8, 172). The game links each quad at the head of its slot: the commands
-- go in drawing order (the digits from the left, then the sign, the class or affinity, the equipment).
local function quad(d, q, x, y, w, h, u, v, tw, th, bgr)
  q.u, q.v, q.w, q.h, q.bgr = u, v, tw, th, bgr -- (descriptors reused: no table per frame)
  d.quad(x, y, w, h, q)
end
M.draw.buff = function(e, d)
  local b = look.buff
  local slot, stat = b.slots[e.slot], b.stats[e.stat]
  if not slot or not stat then return end
  local colour = e.sign > 0 and b.colours.gain or b.colours.loss
  local x, y = e.call_x + b.place.dx, e.call_y - e.rise + b.place.dy
  local stat_x = x + slot[3] + b.gap
  local sign_x = stat_x + stat[3] + b.gap
  local s, f = b.sign, b.digits
  local n = digits(e.value)
  local right = sign_x + s.after + n * f.step -- (the rightmost digit's x)
  local div = 1
  for _ = 2, n do div = div * 10 end
  d.anchor(b.place.anchor)
  d.layer(b.layer)
  for i = n - 1, 0, -1 do
    local digit = e.value // div % 10
    div = div // 10
    quad(d, b.figures, right - i * f.step, y + f.dy, f.w, f.h, digit * f.u_step, f.v, f.w, f.h, colour)
  end
  quad(d, b.words, sign_x, y + s.dy, s.w, s.h, e.sign > 0 and s.gain_u or s.loss_u, s.v, s.w, s.h, colour)
  quad(d, b.words, stat_x, y, stat[3], stat[4], stat[1], stat[2], stat[3], stat[4], colour)
  quad(d, b.words, x, y, slot[3], slot[4], slot[1], slot[2], slot[3], slot[4], colour)
end

-- damage: func_80094B0C (x, y: where the label loop placed it, its record's spread applied). The digits from
-- the left (the game's last linked), each off the screen left out as the game leaves it; a stat's sign and
-- icon after them.
M.draw.damage = function(e, d)
  local m, f = look.damage, look.damage.digits
  local gain = e.sign > 0
  local x, y = e.call_x + m.place.dx, e.call_y + m.place.dy
  local n, offset, colour, width = digits(e.value), 0, 0, 0
  local st = e.pool == "stat" and m.stat or nil
  local icon = st and st.icons[e.stat + 1]
  if st then
    if not icon then return end
    y = y + (gain and -(e.age >> 1) or e.age >> 1) -- (its drift)
    width = (n * f.step + icon[3] + st.padding) // 2
    colour = m.colours.stat.gain
  else
    local pool = m.colours[e.pool]
    if not pool then return end
    local frame = e.age < m.last_frame + 1 and e.age or m.last_frame
    offset = m.bounce[frame + (gain and 0 or m.loss_frame) + 1]
    colour = gain and pool.gain or pool.loss
    width = n * f.centre
  end
  local right = x + width - f.step -- (the rightmost digit's x)
  local div = 1
  for _ = 2, n do div = div * 10 end
  d.anchor(m.place.anchor)
  d.layer(m.layer)
  for i = n - 1, 0, -1 do -- (i: the digits to its right; each halves the bounce, towards zero)
    local digit = e.value // div % 10
    div = div // 10
    local dx = right - i * f.step
    if dx + f.w >= 0 and dx + f.w < f.clip then
      local bounce = offset >= 0 and offset >> i or -((-offset) >> i)
      quad(d, m.figures, dx, y + bounce - f.half, f.w, f.h, digit * f.u_step + f.u, f.v, f.w, f.h, colour)
    end
  end
  if st then
    local s, ix = st.sign, x - width
    quad(d, s, ix + icon[3] + s.gap, y + s.dy, s.w, s.h, gain and s.gain_u or s.loss_u, s.v, s.w, s.h)
    quad(d, st.icon, ix, y - st.half, icon[3], st.h, icon[1], icon[2], icon[3], st.h)
  end
end

-- actor_word: func_8009506C (MISS) or func_80095258 (a combat label) at the label loop's place. The game links
-- each piece at the head of the slot: the commands go last piece first (a label's arrow, linked before its
-- pieces, after them).
local function word_quad(d, q, x, y, w, h, u, v, th, bgr, alpha)
  q.u, q.v, q.w, q.h, q.bgr = u, v, w, th, bgr
  d.quad(x, y, w, h, q, alpha)
end
local function miss(e, d, a)
  local m = a.miss
  local step = e.age < a.enter and e.age or e.age >= a.leave and a.life - e.age or a.enter
  local x = e.call_x + m.dx + a.place.dx
  local y0, y1 = e.call_y + a.place.dy - m.squash[step + 1], e.call_y + a.place.dy + m.squash[step + 1]
  local right = x
  for i = 1, #m.letters do right = right + m.letters[i][3] end
  for i = #m.letters, 1, -1 do
    local l = m.letters[i]
    right = right - l[3]
    if right < 320 and right + l[3] >= 0 then
      word_quad(d, m.sprite, right, y0, l[3], y1 - y0, l[1], l[2], m.h, nil, m.alpha)
    end
  end
end
local function channel(c, step, a)
  if step == 5 then return c // 2 + a.lit end
  if step == 4 then return c // 2 end
  return c * a.fade[step + 1] // 32
end
local function label(e, d, a)
  local entry = a.labels[e.label + 1]
  if not entry or #entry < 2 then return end
  local x, y = e.call_x + a.place.dx, e.call_y + a.place.dy
  local age, step = e.age, 4
  if age < a.enter then
    step = age
    if not e.lowered then x = x + a.slide[step + 1] end
  elseif age < a.lit_until then
    step = 5
  elseif age >= a.leave then
    step = a.life - age
    if not e.lowered then x = x - a.slide[step + 1] end
  elseif age >= a.lit_from then
    step = 5
  end
  local arrow_x = x
  local width = 0
  for i = 2, #entry do width = width + a.pieces[entry[i] + 1][3] end
  x = x - width // 2
  local c = a.colours[(e.lowered and 0 or entry[1]) + 1]
  local bgr = channel(c[1], step, a) | channel(c[2], step, a) << 8 | channel(c[3], step, a) << 16
  local q = step ~= 4 and a.fading or a.held
  local right = x + width
  for i = #entry, 2, -1 do
    local r = a.pieces[entry[i] + 1]
    right = right - r[3]
    if right < 320 and right + r[3] >= 0 then
      word_quad(d, q, right, y - a.half, r[3], a.h, r[1], r[2], a.h, bgr, a.alpha)
    end
  end
  local w = a.arrow
  if e.lowered and age >= w.from then
    local cell = math.min(age - w.from, w.steps)
    word_quad(d, w.sprite, arrow_x + w.dx, y + w.dy, w.w, w.h, cell * w.u_step + w.u, w.v, w.h)
  end
end
M.draw.actor_word = function(e, d)
  local a = look.actor_word
  d.anchor(a.place.anchor)
  d.layer(a.layer)
  if e.word == "miss" then miss(e, d, a) else label(e, d, a) end
end

-- timer: _renderTimer's vs_battle_renderTextRaw (its string, as the game composed it: e.text).
M.draw.timer = function(e, d)
  local t = look.timer
  d.anchor(t.place.anchor)
  d.layer(t.layer)
  d.text_raw(e.text, t.x + t.place.dx, t.y + t.place.dy, t.colour)
end

-- emote: func_80095C18 as it decided (e.draw). The game links each piece at the head of the slot: the balloon
-- (linked last) first, then its marks in the reverse of the game's calls.
local function emote_balloon(d, m, e)
  local q = m.balloon
  q.corners, q.uvs = m.corners[e.side + 1], m.uvs[e.side + 1] -- (reused: no table per frame)
  d.quad(e.call_x + m.place.dx, e.call_y + m.place.dy, 0, 0, q)
end
local function emote_sprite(d, m, e, delta, sprite)
  local x, y = xy(e.call_x + m.place.dx, e.call_y + m.place.dy, delta)
  d.sprite(x, y, sprite)
end
local ARROW_TURNS = { 0, 2, 6, 4 } -- (the arrow's vertices 0, 1, 3, 2 are its points turned by two each)
M.draw.emote = function(e, d)
  local m = look.emote
  d.anchor(m.place.anchor)
  if e.draw == "arrow" then
    local a = m.arrow
    local i, c = a.directions[e.direction], a.quad.corners
    if not i then return end
    for k, step in ipairs(ARROW_TURNS) do
      local at = (i + step) % 8 + 1
      c[2 * k - 1], c[2 * k] = a.dx[at], a.dy[at]
    end
    d.quad(e.call_x + m.place.dx, e.call_y + m.place.dy, 0, 0, a.quad)
    return
  end
  local kind, mark = e.emote, m.marks[e.side + 1]
  if kind == 7 then
    emote_sprite(d, m, e, m.question.offset, m.question.sprite)
    return
  end
  emote_balloon(d, m, e)
  if kind >= 1 and kind <= 3 then
    for k = 0, kind - 1 do emote_sprite(d, m, e, k * m.dot.step + mark, m.dot.sprite) end
  elseif kind == 4 then
    emote_sprite(d, m, e, mark, m.shout)
  elseif kind == 5 then
    emote_sprite(d, m, e, mark + m.heart.offset, m.heart.sprite)
  end
end

for _, kind in ipairs({ "status", "chain", "gauges", "figure", "status_icons", "battle_mode", "ability_icons", "buff",
                        "damage", "actor_word", "timer", "emote" }) do
  rood.hud.claim(kind, function(e, d) return M.draw[kind](e, d) end, { flavour = "classic" })
end

return M
