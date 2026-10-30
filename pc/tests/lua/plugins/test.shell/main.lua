-- The fixture of pc/tests/editor_shell_smoke.py: a tool window that docks into the shell's bottom
-- node and a command the palette lists and runs.
local imgui = rood.imgui
granted = imgui ~= nil
ran, frames = 0, 0
if not granted then return end
rood.dev.window {
  id = "tool", title = "Shell test tool", open = true, size = { 320, 200 },
  draw = function()
    frames = frames + 1
    imgui.Text("shell test tool " .. frames)
  end,
}
command_id = rood.dev.command {
  id = "hello", title = "Say hello from the test plugin", category = "Test", shortcut = "",
  run = function() ran = ran + 1 end,
}
