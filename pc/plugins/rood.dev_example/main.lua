-- A developer tool window written in Lua (pc/docs/Extensions.md, "Developer tool windows").
-- Off by default: turn it on in the Lua console's Plugins list (F1, Window > Lua console) or
-- with RPC lua {action "enable", plugin "rood.dev_example"}; then Window > Lua example.
-- Save this file while the game runs: the window redraws from the new code (hot reload),
-- and stays open.
local imgui = rood.imgui

-- The calls the explorer offers: they only read (rood.dev.rpc reaches every developer
-- method, those that change things too).
local METHODS = { "status", "graphics", "render_stats", "perf", "editor_camera", "lighting" }

local status, status_error = nil, nil
local method, result, result_error = 1, nil, nil
local slider, ticked, tint, note = 0.5, true, { 0.8, 0.6, 0.3 }, "edit me"

local function refresh()
  status, status_error = rood.dev.rpc("status")
end
refresh()
rood.timer.every(0.5, refresh, { clock = "real" })

-- A value as an ImGui tree: tables open, the rest as text.
local function show(name, value)
  if type(value) == "table" then
    if imgui.TreeNode(name) then
      local keys = {}
      for k in pairs(value) do keys[#keys + 1] = k end
      table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
      for _, k in ipairs(keys) do show(tostring(k), value[k]) end
      imgui.TreePop()
    end
  else
    imgui.BulletText(name .. ": " .. tostring(value))
  end
end

rood.dev.window {
  id = "example",
  title = "Lua example",
  size = { 380, 420 },
  draw = function()
    imgui.SeparatorText("The game")
    if status then
      imgui.Text(string.format("vsync %d   presents %d", status.vsync, status.presents))
      if imgui.Button(status.paused and "Resume" or "Pause") then
        rood.dev.rpc("pause", { paused = not status.paused })
        refresh()
      end
      imgui.SetItemTooltip("RPC pause: the game stops between vsyncs; the overlay still draws")
    else
      imgui.TextColored({ 1, 0.4, 0.3, 1 }, tostring(status_error))
    end

    imgui.SeparatorText("RPC explorer")
    local changed
    imgui.SetNextItemWidth(imgui.GetFontSize() * 12)
    changed, method = imgui.Combo("method", method, METHODS)
    imgui.SameLine()
    if imgui.Button("Call") then
      result, result_error = rood.dev.rpc(METHODS[method])
    end
    if result_error then
      imgui.TextWrapped(result_error)
    elseif result then
      if imgui.BeginChild("result", 0, 160, imgui.ChildFlags_Borders) then
        show(METHODS[method], result)
      end
      imgui.EndChild()
    end

    if imgui.CollapsingHeader("Widgets") then
      changed, slider = imgui.SliderFloat("slider", slider, 0, 1)
      changed, ticked = imgui.Checkbox("ticked", ticked)
      changed, tint = imgui.ColorEdit3("tint", tint)
      changed, note = imgui.InputText("note", note)
      imgui.TextDisabled("(kept in the plugin's state until it reloads)")
    end
  end,
}
