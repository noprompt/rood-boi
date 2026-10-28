// Developer tool windows in Lua (the dev.tools grant; pc/docs/Extensions.md "Developer tool windows";
// plan pc/docs/plans/2026-10-27-rood-imgui.md):
//
//   rood.dev.window{id, title, draw[, open][, keys][, size = {w, h}][, size_em][, flags][, replaces]}
//       -> the qualified id
//       a window in the overlay's Window menu, drawn with rood.imgui while it is open and the overlay
//       shows (draw() between the host's Begin and End, under the plugin's call budget). Its open state
//       is remembered across reloads and runs (settings dev_window <id> <0|1>). keys: it takes the
//       keyboard while focused (the editor's own shortcuts, Ctrl+Z, H, stand aside, as for the
//       Material review). size_em: the first size in font heights. replaces: a C++ window's name
//       (pc_lua_dev_replaceable: "material_review"): while this window is registered the C++ one is
//       neither drawn nor in the menu, and its open flag is this window's open state.
//   rood.dev.window_open(id[, open]) -> open    rood.dev.remove_window(id)
//   rood.dev.rpc(method[, params]) -> result | nil, error
//       one developer RPC method (dev_rpc.c), in-process: the same handlers the socket reaches.
//
// A draw that raises (or leaves a Begin/Push open) is rewound with Dear ImGui's error recovery, so the
// overlay's stack stays balanced, and its window shows the error with Retry until then; the plugin's
// other windows and the overlay go on. A draw over its budget is drawn again next frame (the fault
// policy disables a plugin that keeps doing it). RPC lua {action "windows"} lists them, {action
// "window", id, open} opens or closes one.
#include "imgui.h"
#include "imgui_internal.h"
#include "light_prefabs.h"
#include "lua_imgui.h"
#include "lua_runtime.h"

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <cstring>
#include <map>

extern "C" int pc_rpc_call(const char* method, const char* params_json, char* out, int size) __attribute__((weak));

namespace rl {
namespace {
struct Window {
    std::string id, title, menu;
    Plugin* plugin = nullptr;
    unsigned generation = 0;
    int ref = LUA_NOREF;
    bool keys = false;
    float width = 0, height = 0;
    bool em = false; // width and height in font heights
    std::string replaces;
    bool* bound = nullptr; // the replaced C++ window's open flag
    int flags = 0;
    bool failed = false;
    std::string error;
    unsigned long long frames = 0, failures = 0;
    bool focused = false; // it had the keyboard (pc_lua_dev_keys) ...
    int focused_frame = -10; // ... at this ImGui frame
    bool focus_request = false; // RPC lua {action "window", focus}: focused when next drawn
};
std::vector<Window>& windows()
{
    static auto* list = new std::vector<Window>();
    return *list;
}
// C++ windows a Lua window may replace, with their open flags (pc_lua_dev_replaceable).
std::map<std::string, bool*>& replaceable()
{
    static auto* map = new std::map<std::string, bool*>();
    return *map;
}
// Open or closed, by qualified id: what the player left (settings dev_window), outliving reloads.
std::map<std::string, bool>& window_state()
{
    static auto* state = new std::map<std::string, bool>();
    return *state;
}
bool is_open(const Window& w)
{
    if (w.bound)
        return *w.bound;
    auto it = window_state().find(w.id);
    return it != window_state().end() && it->second;
}
Window* find_window(const std::string& id);
void set_open(const std::string& id, bool open, bool save)
{
    if (Window* w = find_window(id); w && w->bound) {
        *w->bound = open;
        return;
    }
    bool& now = window_state()[id];
    if (now == open)
        return;
    now = open;
    if (save)
        save_settings_now();
}
Window* find_window(const std::string& id)
{
    for (Window& w : windows())
        if (w.id == id)
            return &w;
    return nullptr;
}
const size_t MAX_WINDOWS = 32; // a plugin's
const size_t MAX_RPC_REPLY = 300u << 10; // dev_rpc.c: LINE_MAX_BYTES (256 KB) and the envelope

bool name_ok(const std::string& s)
{
    if (s.empty() || s.size() > 48)
        return false;
    for (char c : s)
        if (!(std::islower((unsigned char)c) || std::isdigit((unsigned char)c) || c == '_' || c == '-' || c == '.'))
            return false;
    return true;
}
// "name" in p's namespace; "<p's id>/name" as given (another plugin's: refused by the caller).
std::string qualify(Plugin* p, const std::string& id)
{
    return id.find('/') == std::string::npos ? p->id() + "/" + id : id;
}
std::string own_id(lua_State* L, Plugin* p, int idx, const char* what)
{
    std::string id = qualify(p, luaL_checkstring(L, idx));
    if (id.compare(0, p->id().size() + 1, p->id() + "/") != 0 || !name_ok(id.substr(p->id().size() + 1)))
        luaL_error(L, "rood.dev.%s: '%s' is not one of this plugin's window ids (lowercase letters, digits, _ - .)",
            what, id.c_str());
    return id;
}

void drop_window(Window& w, lua_State* L)
{
    if (L && w.ref != LUA_NOREF && w.plugin && w.generation == w.plugin->generation)
        luaL_unref(L, LUA_REGISTRYINDEX, w.ref);
    w.ref = LUA_NOREF;
}
void drop_windows(Plugin* p)
{
    auto& list = windows();
    for (auto it = list.begin(); it != list.end();)
        if (it->plugin == p) {
            drop_window(*it, p->L);
            it = list.erase(it);
        } else {
            ++it;
        }
}

// rood.dev.window{id, title, draw[, open][, keys][, size][, flags][, menu]}
int api_window(lua_State* L)
{
    Plugin* p = plugin_of(L);
    luaL_checktype(L, 1, LUA_TTABLE);
    if (imgui_host::drawing())
        return luaL_error(L, "rood.dev.window: not inside a window's draw");
    lua_getfield(L, 1, "id");
    std::string id = own_id(L, p, -1, "window");
    lua_pop(L, 1);
    Window w;
    w.id = id;
    lua_getfield(L, 1, "title");
    w.title = lua_type(L, -1) == LUA_TSTRING ? lua_tostring(L, -1) : id.substr(p->id().size() + 1);
    lua_pop(L, 1);
    if (w.title.empty() || w.title.size() > 64 || w.title.find("##") != std::string::npos)
        return luaL_error(L, "rood.dev.window: a title of 1 to 64 bytes, without ##");
    lua_getfield(L, 1, "menu");
    w.menu = lua_type(L, -1) == LUA_TSTRING ? lua_tostring(L, -1) : "Window";
    lua_pop(L, 1);
    if (w.menu != "Window")
        return luaL_error(L, "rood.dev.window: menu is \"Window\" (the only one so far)");
    lua_getfield(L, 1, "keys");
    w.keys = lua_toboolean(L, -1) != 0;
    lua_pop(L, 1);
    lua_getfield(L, 1, "flags");
    w.flags = (int)luaL_optinteger(L, -1, 0) & ~ImGuiWindowFlags_ChildWindow;
    lua_pop(L, 1);
    lua_getfield(L, 1, "replaces");
    if (lua_type(L, -1) == LUA_TSTRING) {
        w.replaces = lua_tostring(L, -1);
        auto it = replaceable().find(w.replaces);
        if (it == replaceable().end())
            return luaL_error(L, "rood.dev.window: no C++ window '%s' to replace", w.replaces.c_str());
        for (const Window& x : windows())
            if (x.replaces == w.replaces && x.id != id)
                return luaL_error(L, "rood.dev.window: %s already replaces '%s'", x.id.c_str(), w.replaces.c_str());
        w.bound = it->second;
    } else if (!lua_isnil(L, -1))
        return luaL_error(L, "rood.dev.window: replaces is a C++ window's name");
    lua_pop(L, 1);
    lua_getfield(L, 1, "size_em");
    w.em = !lua_isnil(L, -1);
    if (!w.em) {
        lua_pop(L, 1);
        lua_getfield(L, 1, "size");
    }
    if (lua_istable(L, -1)) {
        lua_rawgeti(L, -1, 1);
        lua_rawgeti(L, -2, 2);
        w.width = (float)lua_tonumber(L, -2);
        w.height = (float)lua_tonumber(L, -1);
        lua_pop(L, 2);
    } else if (!lua_isnil(L, -1))
        return luaL_error(L, "rood.dev.window: size (size_em) is {width, height}");
    lua_pop(L, 1);
    lua_getfield(L, 1, "open");
    bool has_open = !lua_isnil(L, -1), open = lua_toboolean(L, -1) != 0;
    lua_pop(L, 1);
    lua_getfield(L, 1, "draw");
    luaL_checktype(L, -1, LUA_TFUNCTION);
    Window* old = find_window(id);
    if (!old) {
        size_t mine = 0;
        for (const Window& x : windows())
            mine += x.plugin == p;
        if (mine >= MAX_WINDOWS)
            return luaL_error(L, "rood.dev.window: more than %d windows", (int)MAX_WINDOWS);
    }
    w.plugin = p;
    w.generation = p->generation;
    w.ref = luaL_ref(L, LUA_REGISTRYINDEX);
    if (old) {
        drop_window(*old, L);
        *old = w;
    } else
        windows().push_back(w);
    // The remembered state wins over open = ...: a reload keeps the window as the player left it.
    if (!w.bound && window_state().find(id) == window_state().end() && has_open)
        window_state()[id] = open;
    lua_pushstring(L, id.c_str());
    return 1;
}
// rood.dev.window_open(id[, open]) -> open
int api_window_open(lua_State* L)
{
    Plugin* p = plugin_of(L);
    std::string id = own_id(L, p, 1, "window_open");
    if (!lua_isnoneornil(L, 2)) {
        bool open = lua_toboolean(L, 2) != 0;
        set_open(id, open, true);
        if (Window* w = find_window(id); w && open)
            w->failed = false;
    }
    Window* w = find_window(id);
    auto it = window_state().find(id);
    lua_pushboolean(L, w ? is_open(*w) : it != window_state().end() && it->second);
    return 1;
}
int api_remove_window(lua_State* L)
{
    Plugin* p = plugin_of(L);
    std::string id = own_id(L, p, 1, "remove_window");
    if (imgui_host::drawing())
        return luaL_error(L, "rood.dev.remove_window: not inside a window's draw");
    auto& list = windows();
    for (auto it = list.begin(); it != list.end(); ++it)
        if (it->id == id && it->plugin == p) {
            drop_window(*it, L);
            list.erase(it);
            lua_pushboolean(L, 1);
            return 1;
        }
    lua_pushboolean(L, 0);
    return 1;
}

// Methods Lua may not call: the RPC lua (a plugin running plugins' code: no re-entry), ending the process,
// and those other grants cover (memory.read / memory.write, flags.write).
bool rpc_refused(const std::string& method)
{
    static const char* const refused[] = { "lua", "quit", "restart", "reload", "auth", "read", "write",
        "state_flag", "record", "replay", "input_record" };
    for (const char* r : refused)
        if (method == r)
            return true;
    return false;
}
// rood.dev.rpc(method[, params]) -> result | nil, error
int api_rpc(lua_State* L)
{
    std::string method = luaL_checkstring(L, 1);
    std::string params = "{}";
    if (!lua_isnoneornil(L, 2)) {
        luaL_checktype(L, 2, LUA_TTABLE);
        params = to_json(Value::from_lua(L, 2));
        if (params == "[]")
            params = "{}"; // an empty table
    }
    if (rpc_refused(method))
        return luaL_error(L, "rood.dev.rpc: '%s' is not available to plugins", method.c_str());
    if (!pc_rpc_call) {
        lua_pushnil(L);
        lua_pushstring(L, "rood.dev.rpc: no developer RPC in this build");
        return 2;
    }
    // One call at a time (a handler that runs Lua which calls again is refused: dev_rpc.c's buffers are
    // static), so one buffer serves; the socket's replies are at most 256 KB too.
    static char out[MAX_RPC_REPLY];
    static bool busy;
    if (busy) {
        lua_pushnil(L);
        lua_pushstring(L, "rood.dev.rpc: called from inside another rood.dev.rpc call");
        return 2;
    }
    busy = true;
    int status = pc_rpc_call(method.c_str(), params.c_str(), out, (int)sizeof out);
    busy = false;
    if (status < 0) {
        lua_pushnil(L);
        lua_pushfstring(L, "%s: %s", method.c_str(), out);
        return 2;
    }
    prefab::Json reply;
    std::string why;
    if (!prefab::json_parse(out, reply, &why) || reply.type != prefab::Json::Object) {
        lua_pushnil(L);
        lua_pushfstring(L, "%s: an unreadable reply (%s)", method.c_str(), why.c_str());
        return 2;
    }
    if (const prefab::Json* e = reply.get("error")) {
        const prefab::Json* m = e->get("message");
        std::string text = m && m->type == prefab::Json::String ? m->string : "failed";
        if (text.compare(0, method.size() + 1, method + ":") != 0) // (most handlers name themselves already)
            text = method + ": " + text;
        lua_pushnil(L);
        lua_pushstring(L, text.c_str());
        return 2;
    }
    const prefab::Json* result = reply.get("result");
    push(L, result ? from_json(*result) : Value());
    return 1;
}

void open_dev_tools(lua_State* L, Plugin*)
{
    set_cfunction(L, -1, "window", api_window);
    set_cfunction(L, -1, "window_open", api_window_open);
    set_cfunction(L, -1, "remove_window", api_remove_window);
    set_cfunction(L, -1, "rpc", api_rpc);
}

// Dear ImGui's state put back as it was (a failed draw): every Begin, Push and table closed, quietly
// (no assertion, no error tooltip: the window shows the error itself).
void recover(const ImGuiErrorRecoveryState& state)
{
    ImGuiIO& io = ImGui::GetIO();
    bool assert_on = io.ConfigErrorRecoveryEnableAssert, tooltip = io.ConfigErrorRecoveryEnableTooltip;
    io.ConfigErrorRecoveryEnableAssert = false;
    io.ConfigErrorRecoveryEnableTooltip = false;
    ImGui::ErrorRecoveryTryToRecoverState(&state);
    io.ConfigErrorRecoveryEnableAssert = assert_on;
    io.ConfigErrorRecoveryEnableTooltip = tooltip;
}

void draw_window(size_t index)
{
    Window& w = windows()[index];
    Plugin* p = w.plugin;
    std::string label = w.title + "###lua:" + w.id;
    bool open = true;
    if (w.width > 0 && w.height > 0) {
        float unit = w.em ? ImGui::GetFontSize() : 1.0f;
        ImGui::SetNextWindowSize(ImVec2(w.width * unit, w.height * unit), ImGuiCond_FirstUseEver);
    }
    if (w.focus_request) {
        w.focus_request = false;
        ImGui::SetNextWindowFocus();
    }
    if (w.failed) {
        w.focused = false;
        if (ImGui::Begin(label.c_str(), &open)) {
            ImGui::TextColored(ImVec4(1, 0.4f, 0.3f, 1), "This window's draw failed:");
            ImGui::TextWrapped("%s", w.error.c_str());
            if (ImGui::Button("Retry"))
                w.failed = false;
            ImGui::SameLine();
            ImGui::TextDisabled("(or save the plugin's files: it reloads)");
        }
        ImGui::End();
    } else {
        ImGuiErrorRecoveryState state;
        ImGui::ErrorRecoveryStoreState(&state);
        bool visible = ImGui::Begin(label.c_str(), &open, w.flags);
        w.focused = visible && w.keys && ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows);
        w.focused_frame = ImGui::GetFrameCount();
        std::string error, unbalanced;
        bool ok = true;
        if (visible) {
            int ref = w.ref;
            imgui_host::begin_draw(p, w.focused);
            ok = run(p, "window draw", BUDGET_CALL, [ref](lua_State* L) {
                lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
                lua_call(L, 0, 0);
            }, &error);
            unbalanced = imgui_host::end_draw();
            ++w.frames;
        }
        // (run never unloads: settle waits for no call in progress, so w and p are still these)
        if (ok && unbalanced.empty()) {
            ImGui::End();
        } else {
            recover(state);
            if (ok) { // balanced in Lua's eyes but not in Dear ImGui's: the draw's own fault
                error = "the draw left open: " + unbalanced + " (each needs its End/Pop)";
                fault(p, "window draw", error, false, true);
            } else if (!unbalanced.empty())
                error += "\n(open when it failed: " + unbalanced + ")";
            if (!ok && p->budget.killed) {
                // over its budget (a slow frame): drawn again next frame
            } else {
                w.failed = true;
                w.error = error;
                ++w.failures;
                log(LOG_WARN, p->id(), "window " + w.id + ": its draw failed; it shows the error until Retry "
                                       "or the plugin reloads");
            }
            w.focused = false;
        }
    }
    if (!open)
        set_open(w.id, false, true);
}

bool windows_rpc(const std::string& action, const prefab::Json& params, std::string* reply, std::string* error,
    bool* refused)
{
    if (action != "windows" && action != "window")
        return false;
    if (action == "window") {
        const prefab::Json* id = params.get("id");
        if (!id || id->type != prefab::Json::String) {
            *error = "window needs id (\"<plugin>/<name>\")";
            *refused = true;
            return true;
        }
        Window* w = find_window(id->string);
        if (!w) {
            *error = "no window '" + id->string + "'";
            *refused = true;
            return true;
        }
        if (const prefab::Json* o = params.get("open")) {
            set_open(w->id, o->type == prefab::Json::Bool ? o->boolean : o->number != 0, true);
            if (is_open(*w))
                w->failed = false;
        }
        if (const prefab::Json* r = params.get("retry"); r && r->type == prefab::Json::Bool && r->boolean)
            w->failed = false;
        if (const prefab::Json* f = params.get("focus"); f && f->type == prefab::Json::Bool && f->boolean)
            w->focus_request = true;
    }
    std::string out = "{\"windows\":[";
    for (size_t i = 0; i < windows().size(); ++i) {
        const Window& w = windows()[i];
        out += std::string(i ? "," : "") + "{\"id\":" + prefab::json_quote(w.id) + ",\"title\":" + prefab::json_quote(w.title)
            + ",\"plugin\":" + prefab::json_quote(w.plugin->id()) + ",\"menu\":" + prefab::json_quote(w.menu)
            + ",\"open\":" + (is_open(w) ? "true" : "false") + ",\"keys\":" + (w.keys ? "true" : "false")
            + ",\"focused\":" + (w.focused ? "true" : "false") + ",\"replaces\":" + prefab::json_quote(w.replaces) + ",\"failed\":" + (w.failed ? "true" : "false")
            + ",\"error\":" + prefab::json_quote(w.error) + ",\"frames\":" + std::to_string(w.frames)
            + ",\"failures\":" + std::to_string(w.failures) + "}";
    }
    out += "]}";
    *reply = out;
    return true;
}

struct Register {
    Register()
    {
        dev_openers().push_back(open_dev_tools);
        unload_hooks().push_back(drop_windows);
        rpc_actions().push_back(windows_rpc);
    }
} register_dev_tools;
} // namespace
} // namespace rl

// The overlay (dev_overlay.cpp): the Window menu's entries for Lua windows, by title.
extern "C" void pc_lua_dev_menu_items(void)
{
    std::vector<size_t> order(rl::windows().size());
    for (size_t i = 0; i < order.size(); ++i)
        order[i] = i;
    std::sort(order.begin(), order.end(),
        [](size_t a, size_t b) { return rl::windows()[a].title < rl::windows()[b].title; });
    for (size_t i : order) {
        rl::Window& w = rl::windows()[i];
        bool open = rl::is_open(w);
        ImGui::PushID(w.id.c_str());
        if (ImGui::MenuItem(w.title.c_str(), nullptr, &open)) {
            rl::set_open(w.id, open, true);
            if (open)
                w.failed = false;
        }
        if (ImGui::IsItemHovered())
            ImGui::SetTooltip("%s (Lua: %s)", w.id.c_str(), w.plugin->id().c_str());
        ImGui::PopID();
    }
}

// The overlay's windows pass (while it shows): every open Lua window.
extern "C" void pc_lua_dev_windows(void)
{
    if (!rl::initialized())
        return;
    for (size_t i = 0; i < rl::windows().size(); ++i) {
        if (!rl::is_open(rl::windows()[i])) {
            rl::windows()[i].focused = false;
            continue;
        }
        rl::draw_window(i);
    }
}

// A Lua window with keys = true had the keyboard last frame (the editor's shortcuts run before the
// windows): the editor's shortcuts stand aside.
extern "C" int pc_lua_dev_keys(void)
{
    for (const rl::Window& w : rl::windows())
        if (w.focused && rl::is_open(w) && ImGui::GetFrameCount() - w.focused_frame <= 1)
            return !ImGui::GetIO().WantTextInput;
    return 0;
}

// A C++ tool window a Lua window may replace (rood.dev.window{replaces = name}): its open flag.
extern "C" void pc_lua_dev_replaceable(const char* name, bool* open)
{
    rl::replaceable()[name] = open;
}
// A Lua window replaces it now: the C++ one is neither drawn nor in the Window menu.
extern "C" int pc_lua_dev_replaced(const char* name)
{
    for (const rl::Window& w : rl::windows())
        if (w.replaces == name)
            return 1;
    return 0;
}

// settings.cfg dev_window <id> <0|1> (project_settings.cpp through pc_lua_settings_parse).
extern "C" int pc_lua_dev_settings_parse(const char* key, const char* rest)
{
    if (std::strcmp(key, "dev_window"))
        return 0;
    char id[128];
    int open;
    if (std::sscanf(rest, "%127s %d", id, &open) == 2)
        rl::window_state()[id] = open != 0;
    return 1;
}
extern "C" void pc_lua_dev_settings_write(FILE* f)
{
    for (const auto& e : rl::window_state())
        std::fprintf(f, "dev_window %s %d\n", e.first.c_str(), e.second ? 1 : 0);
}
