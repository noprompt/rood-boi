-- The fixture of pc/tests/lua_imgui_smoke.py: two windows drawn with rood.imgui. The test drives
-- them through RPC lua (eval in this plugin: the globals below) and reads what the draws saw.
local imgui = rood.imgui
if not imgui then
  granted = false
  return
end
granted = true
VERSION = 1                      -- the test edits this line (hot reload)
value, text, checked, choice, tint = 0.25, "hello", false, 2, { 1, 0.5, 0.25 }
seen = {}                        -- what the widgets gave back last frame
frames, other_frames, keys_seen = 0, 0, {}
fail, unbalanced = false, false
status, rpc_error = nil, nil

rood.dev.window {
  id = "panel", title = "Test panel", keys = true, size = { 320, 260 },
  draw = function()
    frames = frames + 1
    drawn_version = VERSION
    imgui.Text("version " .. VERSION)
    local changed
    changed, value = imgui.SliderFloat("value", value, 0, 1)
    changed, text = imgui.InputText("text", text)
    changed, checked = imgui.Checkbox("checked", checked)
    changed, choice = imgui.Combo("choice", choice, { "one", "two", "three" })
    changed, tint = imgui.ColorEdit3("tint", tint)
    seen = { value = value, text = text, checked = checked, choice = choice, tint = tint }
    if imgui.BeginTable("t", 2, imgui.TableFlags_Borders) then
      imgui.TableNextRow(); imgui.TableNextColumn(); imgui.Text("a")
      imgui.PushID(1); imgui.TableNextColumn(); imgui.Text("b"); imgui.PopID()
      imgui.EndTable()
    end
    if imgui.IsKeyPressed("A", false) then keys_seen[#keys_seen + 1] = "A" end
    if imgui.IsKeyPressed(imgui.Key_Enter, false) and imgui.GetIO().KeyCtrl then
      keys_seen[#keys_seen + 1] = "Ctrl+Enter"
    end
    if fail then error("deliberate failure") end
    if unbalanced then imgui.PushID("left open"); imgui.BeginGroup() end
  end,
}

rood.dev.window {
  id = "other", title = "Other panel", open = true,
  draw = function()
    other_frames = other_frames + 1
    imgui.Text("still here")
  end,
}

function call_rpc()
  status, rpc_error = rood.dev.rpc("status")
  local none, err = rood.dev.rpc("no_such_method", { x = 1 })
  local refused_ok, refused = pcall(rood.dev.rpc, "lua", { action = "plugins" })
  return { vsync = status and status.vsync, none = none, err = err, refused_ok = refused_ok,
           refused = tostring(refused) }
end
