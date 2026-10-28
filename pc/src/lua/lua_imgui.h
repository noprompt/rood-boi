/* rood.imgui and the developer tool windows (pc/docs/Extensions.md "Developer tool windows";
 * plan pc/docs/plans/2026-10-27-rood-imgui.md). Game side: lua_api_imgui.cpp binds Dear ImGui,
 * lua_dev_tools.cpp owns the windows (rood.dev.window), draws them inside the overlay's frame and
 * bridges rood.dev.rpc to the developer RPC. Both need the dev.tools grant. */
#ifndef ROOD_LUA_IMGUI_H
#define ROOD_LUA_IMGUI_H
#include "rl_internal.h"

namespace rl {
namespace imgui_host {
/* A window's draw starts: rood.imgui answers p's calls only, with an empty scope stack;
 * keys: its window has the keyboard (focused, nothing typed, the camera not flying). */
void begin_draw(Plugin* p, bool keys);
/* It ended: the scopes it left open ("BeginTable, PushID"), "" when balanced; the stack is cleared. */
std::string end_draw();
Plugin* drawing(); /* the plugin whose window draws now, else nullptr */
void open(lua_State* L, Plugin* p); /* rood.imgui on the rood table on top (the dev.tools grant) */
} // namespace imgui_host
} // namespace rl
#endif
