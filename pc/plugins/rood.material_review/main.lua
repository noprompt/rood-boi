-- Window > Material review in Lua (pc/docs/Materials.md "Reviewing in the game"; the C++ window it
-- replaces while on: pc/src/material_review.cpp, which keeps the review's state and does the work).
-- Everything goes through RPC material_review (rood.dev.rpc), so this file is only the window: edit
-- it while the game runs and the window redraws from the saved file.
--
-- Off by default: turn it on in the Lua console's Plugins list (F1, Window > Lua console); Window >
-- Material review is then this one. Off again, the C++ window comes back.
local imgui = rood.imgui
local rpc = rood.dev.rpc

local GREEN, RED, AMBER, ERROR = { 0.5, 0.9, 0.5, 1 }, { 0.9, 0.5, 0.5, 1 }, { 1, 0.8, 0.4, 1 }, { 1, 0.5, 0.4, 1 }
local STATUS_NAMES = { "all", "undecided", "accepted", "rejected" }
local CONFIDENCE_NAMES = { "all", "high", "medium", "low" }
local PAGE = 200 -- proposals a list call brings (the RPC's replies stay small)

local st              -- the review's status (RPC material_review), read every frame
local rows, total, counts = {}, 0, { undecided = 0, accepted = 0, rejected = 0 }
local list_key        -- what the rows were read for (filters, decisions, selection)
local path, path_seen = "", nil
local message         -- the last refused action's reason (else the review's own status line)
local scroll_to_selected, last_selected = false, nil

-- One action; the reply is the status for every action but list. A refusal becomes the message.
local function act(action, params)
  params = params or {}
  params.action = action
  local reply, err = rpc("material_review", params)
  if not reply then
    message = (err or "failed"):gsub("^material_review: ", "")
    return nil
  end
  message = nil
  if reply.count ~= nil then st = reply end
  return reply
end

local function index_of(list, value)
  for i, v in ipairs(list) do
    if v == value then return i end
  end
  return 1
end
local function tip(text)
  if imgui.IsItemHovered(imgui.HoveredFlags_ForTooltip) then imgui.SetTooltip(text) end
end
local function preset_names()
  local names = { "none" }
  for _, p in ipairs(st.presets) do names[#names + 1] = p.name end
  return names
end
local function preset_values(name)
  for _, p in ipairs(st.presets) do
    if p.name == name then return p end
  end
  return { roughness = 1, specular = 0, metal = 0, auto_height = false, bump = 1 }
end
local function current_preset()
  return st.entry and st.entry.preset or "none"
end

-- The window's keys, while it has the keyboard (imgui.HasKeys: focused, nothing typed, the camera
-- not flying). Decisions are Ctrl chords only: a bare A accepted while strafing left.
local function keys()
  if not imgui.HasKeys() or imgui.IsAnyItemActive() then return end
  local io = imgui.GetIO()
  local pressed = function(k) return imgui.IsKeyPressed(k, false) end
  if io.KeyCtrl and not io.KeyAlt and not io.KeyShift then
    if pressed("Enter") or pressed("KeypadEnter") then act("decide", { decision = "accept" }) end
    if pressed("Backspace") then act("decide", { decision = "reject" }) end
    if pressed("Z") then act("undo") end
    return
  end
  if io.KeyAlt or io.KeyShift or io.KeySuper then return end
  if pressed("N") or pressed("GamepadR1") then act("select", { next = true }) end
  if pressed("P") or pressed("GamepadL1") then act("select", { previous = true }) end
  if pressed("U") then act("select", { undecided = true }) end
  if not st.selected then return end
  if pressed("F") then act("focus") end
  if pressed("B") or pressed("GamepadR2") then act("preview", { on = not st.preview }) end
  if pressed("H") or pressed("GamepadL2") then act("preview", { highlight = not st.highlight }) end
  if pressed("O") then act("preview", { isolate = not st.isolate }) end
  if pressed("G") then act("go", { next = true }) end
end

local function filters()
  local f, font, changed = st.filters, imgui.GetFontSize()
  imgui.SetNextItemWidth(font * 7)
  local status
  changed, status = imgui.Combo("##status", index_of(STATUS_NAMES, f.status), STATUS_NAMES)
  if changed then act("filters", { status = STATUS_NAMES[status] }) end
  imgui.SameLine()
  imgui.SetNextItemWidth(font * 8)
  if imgui.BeginCombo("##preset", f.preset == "" and "every preset" or f.preset) then
    if imgui.Selectable("every preset", f.preset == "") then act("filters", { preset = "" }) end
    for _, n in ipairs(preset_names()) do
      if imgui.Selectable(n, f.preset == n) then act("filters", { preset = n }) end
    end
    imgui.EndCombo()
  end
  imgui.SameLine()
  imgui.SetNextItemWidth(font * 6)
  local confidence
  changed, confidence = imgui.Combo("##confidence", index_of(CONFIDENCE_NAMES, f.confidence), CONFIDENCE_NAMES)
  if changed then act("filters", { confidence = CONFIDENCE_NAMES[confidence] }) end
  imgui.SameLine()
  imgui.SetNextItemWidth(font * 6)
  local zone
  changed, zone = imgui.InputInt("Zone", f.zone)
  if changed then act("filters", { zone = math.max(-1, zone) }) end
  tip("-1: every zone")
end

-- The rows the filters pass, read again when what they depend on changed.
local function refresh_list()
  local f, selected = st.filters, st.selected and st.selected.index or -1
  local key = table.concat({ st.path, st.count, st.decided, #st.undo, st.undo[1] or "", f.status, f.preset,
    f.confidence, f.zone, selected }, "|")
  if selected ~= last_selected then
    scroll_to_selected, last_selected = true, selected
  end
  if key == list_key then return end
  list_key = key
  local read, offset = {}, 0
  repeat
    local page = act("list", { offset = offset, limit = PAGE })
    if not page then break end
    for _, row in ipairs(page.proposals) do read[#read + 1] = row end
    total, counts = page.total, page.counts
    offset = offset + PAGE
  until offset >= total or #page.proposals == 0
  rows = read
end

local function proposal_list()
  refresh_list()
  imgui.Text(string.format("%d shown of %d: %d undecided, %d accepted, %d rejected", total, st.count,
    counts.undecided, counts.accepted, counts.rejected))
  local line = imgui.GetTextLineHeightWithSpacing()
  if imgui.BeginListBox("##proposals", -1, line * 9) then
    local selected = st.selected and st.selected.index
    local text = imgui.GetStyleColorVec4(imgui.Col_Text)
    imgui.ListClipper_Begin(#rows)
    while true do
      local more, first, last = imgui.ListClipper_Step()
      if not more then break end
      for i = first, last do
        local p = rows[i]
        local mark = p.decision == "" and "  " or p.decision == "accept" and "A " or "R "
        local preset = (p.decided_preset or "") ~= "" and p.decided_preset or p.preset
        local label = string.format("%s%s  %6.2f  %-12s %-6s %3d rooms  %s", mark, p.id, p.coverage, preset,
          p.confidence, p.room_count, p.first_room)
        imgui.PushStyleColor(imgui.Col_Text, p.decision == "" and text or p.decision == "accept" and GREEN or RED)
        if imgui.Selectable(label, p.index == selected) then act("select", { index = p.index }) end
        imgui.PopStyleColor()
      end
    end
    if scroll_to_selected then -- (the clipper skips rows out of view: scroll by the row's place)
      for i, p in ipairs(rows) do
        if p.index == selected then imgui.SetScrollY((i - 1) * line - line * 4) end
      end
      scroll_to_selected = false
    end
    imgui.EndListBox()
  end
end

-- A setting of "Look and behaviour": applied while it changes, written when let go.
local function setting(key, changed, value)
  if changed then act("settings", { [key] = value, save = false }) end
  if imgui.IsItemDeactivatedAfterEdit() then act("settings") end
end
local function look_and_behaviour()
  local s, changed, v = st.settings
  imgui.SeparatorText("Highlight")
  changed, v = imgui.ColorEdit3("Colour", s.highlight_rgb); setting("highlight_rgb", changed, v)
  changed, v = imgui.Checkbox("Flat colour (else the texel's colour x it)", s.highlight_flat)
  setting("highlight_flat", changed, v)
  changed, v = imgui.SliderFloat("Strength", s.highlight_strength, 0, 4, "%.2f"); setting("highlight_strength", changed, v)
  changed, v = imgui.SliderFloat("Pulses a second", s.highlight_rate, 0, 6, "%.1f"); setting("highlight_rate", changed, v)
  changed, v = imgui.SliderFloat("Pulse low point", s.highlight_floor, 0, 1, "%.2f"); setting("highlight_floor", changed, v)
  imgui.SeparatorText("Isolate")
  changed, v = imgui.SliderFloat("Dim the rest", s.isolate_dim, 0, 1, "%.2f"); setting("isolate_dim", changed, v)
  changed, v = imgui.SliderFloat("Grey the rest", s.isolate_grey, 0, 1, "%.2f"); setting("isolate_grey", changed, v)
  imgui.SeparatorText("Focus")
  changed, v = imgui.SliderFloat("Margin", s.focus_margin, 0.5, 4, "%.2f"); setting("focus_margin", changed, v)
  changed, v = imgui.SliderFloat("Join within", s.focus_join, 8, 2048, "%.0f units", imgui.SliderFlags_Logarithmic)
  setting("focus_join", changed, v)
  tip("Surfaces closer than this are one patch; Focus frames the largest patch.")
  changed, v = imgui.SliderFloat("View from", s.focus_view, 0, 1, "%.2f"); setting("focus_view", changed, v)
  tip("0: straight along the surfaces' normal; 1: from the player's side.")
  changed, v = imgui.SliderFloat("Nearest", s.focus_min, 16, 8192, "%.0f units", imgui.SliderFlags_Logarithmic)
  setting("focus_min", changed, v)
  changed, v = imgui.SliderFloat("Farthest", s.focus_max, 16, 16384, "%.0f units", imgui.SliderFlags_Logarithmic)
  setting("focus_max", changed, v)
  changed, v = imgui.Checkbox("Cut to focus aims at the surfaces", s.focus_cut); setting("focus_cut", changed, v)
  imgui.SeparatorText("Review")
  changed, v = imgui.Checkbox("Next undecided after a decision", s.advance); setting("advance", changed, v)
  changed, v = imgui.Checkbox("Go to a proposal's room when selected", s.auto_go); setting("auto_go", changed, v)
end

-- The entry's response (Details > Material's controls): a field from the preset shows greyed.
local TUNE = {
  { "roughness", "Roughness", "0 mirror, 1 fully rough (a roughness map overrides it per texel)" },
  { "specular", "Specular", "Fraction of a dielectric's reflectance (4% at normal incidence); keep it subtle" },
  { "metal", "Metal", "0 stone, wood, glass; 1 bare metal (tinted reflections, no diffuse light)" },
}
local function fine_tune(preset)
  local e, base, changed, v = st.entry, preset_values(preset)
  local function field(key, own, draw, help)
    if not own then imgui.PushStyleColor(imgui.Col_Text, imgui.GetStyleColorVec4(imgui.Col_TextDisabled)) end
    changed, v = draw()
    if changed then act("tune", { [key] = v }) end
    if not own then imgui.PopStyleColor() end
    tip(help .. (own and "" or "\n(from the preset)"))
  end
  if imgui.BeginCombo("Preset", preset) then -- (Details > Material's: with the presets' values)
    if imgui.Selectable("(none)", false) then act("preset", { preset = "none" }) end
    for _, pr in ipairs(st.presets) do
      local label = string.format("%s  (rough %.2f, spec %.2f, metal %.2f)", pr.name, pr.roughness, pr.specular,
        pr.metal)
      if imgui.Selectable(label, pr.name == preset) then act("preset", { preset = pr.name }) end
    end
    imgui.EndCombo()
  end
  for _, t in ipairs(TUNE) do
    local key = t[1]
    field(key, e[key] ~= nil, function() return imgui.SliderFloat(t[2], e[key] or base[key], 0, 1, "%.2f") end, t[3])
  end
  local auto = e.auto_height
  if auto == nil then auto = base.auto_height end
  changed, v = imgui.Checkbox("Estimate the height from the colours", auto)
  if changed then act("tune", { auto_height = v }) end
  tip("auto_height: bumps from the texture's luminance (dark low, bright high) where it has\nno height.png. "
    .. "Global switch and strength: Graphics > Lighting quality." .. (e.auto_height ~= nil and "" or "\n(from the preset)"))
  field("bump", e.bump ~= nil, function() return imgui.SliderFloat("Relief", e.bump or base.bump, 0, 4, "x %.2f") end,
    "bump: this surface's multiple of the global relief depth (bump_strength)")
end

local function details()
  local p = st.selected
  imgui.SeparatorText(p.id)
  if p.kind == "palette" then
    imgui.Text(string.format("Palette %s: %.2f rooms' worth of screen", p.clut, p.coverage))
  else
    imgui.Text(string.format("Texture %s %d x %d (15-bit): %.2f rooms' worth of screen", p.key, p.size[1], p.size[2],
      p.coverage))
  end
  imgui.TextWrapped(string.format("Proposed %s (%s): %s", p.preset, p.confidence, p.reason))
  if #p.alternatives > 0 then imgui.TextDisabled("Alternatives: " .. table.concat(p.alternatives, ", ")) end
  if #p.in_catalog > 0 then
    imgui.TextDisabled("Already in the catalog: " .. table.concat(p.in_catalog, ", ")
      .. " (a texture's own entry wins over a palette entry)")
  end
  -- Where the review stands: the room, what the surfaces show, the decision.
  local z, r = st.room[1], st.room[2]
  local here
  for i, room in ipairs(p.rooms) do
    if room.room[1] == z and room.room[2] == r then here = i end
  end
  local top = p.rooms[1].room
  if here then
    imgui.TextColored(GREEN, string.format("Room %02d/%02d %s: one of its %d rooms (%.1f%% of its surfaces' screen)",
      z, r, p.rooms[here].name, #p.rooms, p.rooms[here].share * 100))
  else
    imgui.TextColored(AMBER, string.format("Room %02d/%02d: not one of its rooms (Focus goes to %02d/%02d first)", z, r,
      top[1], top[2]))
  end
  local preset = current_preset()
  if preset == "none" then
    imgui.Text("Showing: the surfaces as they are (the preset is none)")
  elseif st.preview then
    imgui.TextColored(GREEN, "Showing: PROPOSED " .. preset .. " (B: before)")
  else
    imgui.TextColored(AMBER, "Showing: BEFORE, without a material (B: proposed " .. preset .. ")")
  end
  if p.decision == "" then
    imgui.Text("Decision: undecided")
  else
    imgui.TextColored(p.decision == "accept" and GREEN or RED, string.format("Decision: %s %s%s%s",
      p.decision == "accept" and "accepted" or "rejected", p.decided_preset or "", (p.entry or "") == "" and "" or ", entry ",
      p.entry or ""))
  end
  if st.focus.pending then imgui.TextColored(AMBER, string.format("Focus: going to %02d/%02d...", top[1], top[2])) end
  -- Finding the surfaces: Focus, the highlight, Isolate.
  local changed, v
  if imgui.Button("Focus (F)") then act("focus") end
  tip("Points the free camera at the largest patch of these surfaces in this room\n"
    .. "(going to the proposal's top room first when this is none of its rooms).")
  imgui.SameLine()
  changed, v = imgui.Checkbox("Highlight (H)", st.highlight)
  if changed then act("preview", { highlight = v }) end
  tip("Pulses the surfaces in the highlight colour.")
  imgui.SameLine()
  changed, v = imgui.Checkbox("Isolate (O)", st.isolate)
  if changed then act("preview", { isolate = v }) end
  tip("Dims and greys everything else: only these surfaces keep their colour.")
  if st.highlight or st.isolate then
    if st.highlight_cells > 0 then
      imgui.TextDisabled(string.format("%d texels marked in view", st.highlight_cells))
    else
      imgui.TextColored(AMBER, "None of its surfaces are drawn here: Focus or Go to one of its rooms")
    end
  end
  -- Rooms
  local line = imgui.GetTextLineHeightWithSpacing()
  if imgui.BeginTable("##rooms", 3, imgui.TableFlags_ScrollY | imgui.TableFlags_RowBg, -1,
      line * math.min(6, #p.rooms + 1)) then
    imgui.TableSetupColumn("go", imgui.TableColumnFlags_WidthFixed)
    imgui.TableSetupColumn("share", imgui.TableColumnFlags_WidthFixed)
    imgui.TableSetupColumn("room")
    for i, room in ipairs(p.rooms) do
      imgui.TableNextRow()
      imgui.TableNextColumn()
      imgui.PushID(i)
      if i == here then
        imgui.TextColored(GREEN, "here")
      elseif imgui.SmallButton("Go") then
        act("go", { room = room.room })
      end
      imgui.PopID()
      imgui.TableNextColumn()
      imgui.Text(string.format("%5.1f%%", room.share * 100))
      imgui.TableNextColumn()
      imgui.Text(string.format("%02d/%02d  %s", room.room[1], room.room[2], room.name))
    end
    imgui.EndTable()
  end
  if imgui.Button("Next room (G)") then act("go", { next = true }) end
  imgui.SameLine()
  changed, v = imgui.Checkbox("Enemies", st.settings.enemies)
  if changed then act("settings", { enemies = v }) end
  imgui.SameLine()
  changed, v = imgui.Checkbox("Scripts", st.settings.scripts)
  if changed then act("settings", { scripts = v }) end
  tip("Go enters rooms as the survey did: without enemies or scripts unless ticked.")
  changed, v = imgui.Checkbox("Proposed material (B: before / after)", st.preview)
  if changed then act("preview", { on = v }) end
  if imgui.TreeNode("Look and behaviour") then
    look_and_behaviour()
    imgui.TreePop()
  end
  -- The material: the preset and the fine-tuning.
  if imgui.BeginCombo("Proposed preset", preset) then
    for _, n in ipairs(preset_names()) do
      if imgui.Selectable(n .. (n == p.preset and "  (proposed)" or ""), n == preset) then act("preset", { preset = n }) end
    end
    imgui.EndCombo()
  end
  if preset ~= "none" and imgui.TreeNode("Fine-tune") then
    fine_tune(preset)
    imgui.TreePop()
  end
  imgui.PushStyleColor(imgui.Col_Button, { 0.2, 0.45, 0.25, 1 })
  if imgui.Button("Accept (Ctrl+Enter)") then act("decide", { decision = "accept" }) end
  imgui.PopStyleColor()
  imgui.SameLine()
  imgui.PushStyleColor(imgui.Col_Button, { 0.5, 0.22, 0.22, 1 })
  if imgui.Button("Reject (Ctrl+Backspace)") then act("decide", { decision = "reject" }) end
  imgui.PopStyleColor()
  imgui.SameLine()
  local decided = st.selected and st.selected.decision or ""
  if decided ~= "" and imgui.Button("Clear decision") then act("decide", { decision = "clear" }) end
  local entry = st.selected and st.selected.entry or ""
  if decided == "accept" and entry ~= "" then
    imgui.SameLine()
    if imgui.Button("Open in Details > Material") then
      rpc("material", { action = "select", id = entry })
      rpc("editor_ui", { details = "material" })
    end
  end
end

local function draw()
  local reply, err = rpc("material_review")
  if not reply then
    imgui.TextColored(ERROR, tostring(err))
    return
  end
  st = reply
  keys()
  imgui.TextWrapped("How to review: 1. pick a proposal  2. Focus (F) to see its surfaces  3. compare before / "
    .. "after (B)  4. tune the preset  5. Accept or Reject (buttons below)")
  if path_seen ~= st.path then path, path_seen = st.path, st.path end
  imgui.SetNextItemWidth(-imgui.GetFontSize() * 5)
  local _
  _, path = imgui.InputText("##path", path)
  imgui.SameLine()
  if imgui.Button("Load") then act("load", { path = path }) end
  if st.error ~= "" then imgui.TextColored(ERROR, st.error) end
  filters()
  proposal_list()
  if st.selected then details() end
  imgui.BeginDisabled(#st.undo == 0)
  if imgui.Button(#st.undo == 0 and "Undo (Ctrl+Z)" or ("Undo " .. st.undo[1] .. " (Ctrl+Z)")) then act("undo") end
  imgui.EndDisabled()
  local line = message or st.status
  if line ~= "" then imgui.TextWrapped(line) end
  imgui.PushStyleColor(imgui.Col_Text, imgui.GetStyleColorVec4(imgui.Col_TextDisabled))
  imgui.TextWrapped(string.format("Keys %s: N / P next / previous, U next undecided, F focus, B before / after, "
    .. "H highlight, O isolate, G next room, Ctrl+Enter accept, Ctrl+Backspace reject, Ctrl+Z undo (pad L1 / R1, "
    .. "R2, L2). None while the camera flies (right mouse held).",
    imgui.HasKeys() and "(this window has the keyboard)" or "(click this window first)"))
  imgui.PopStyleColor()
end

rood.dev.window {
  id = "review",
  title = "Material review",
  replaces = "material_review", -- the C++ window's place in Window, and its open flag
  keys = true,
  size_em = { 46, 56 },
  draw = draw,
}

return { act = act, draw = draw } -- (the REPL's M)
