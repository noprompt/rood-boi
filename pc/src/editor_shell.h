// The editor shell (pc/docs/plans/2026-10-30-editor-shell-design.md, plan
// 2026-10-30-editor-shell-plan.md): Dear ImGui docking on, one workspace while
// the editor shows. The game picture is the "Game" panel: its content
// rectangle is the presenters' inset (pc_gl_inset; gl_present.c and
// vk_present.c place the picture inside it at the game's aspect, so pc_gl_view
// stays the one rectangle picking, handles, the HUD and the menus map
// through), and a hit-test hole, so over the picture Dear ImGui reports no
// hovered window, as over the bare picture before. A default layout
// (Outliner + Library left, Game centre, Details right, tool windows tabbed
// below) is built on a fresh imgui.ini and by Window > Reset layout; the
// user's layout persists in imgui.ini (per user, never committed). The
// command palette (Ctrl+Shift+P) searches editor_commands.h's registry.
#pragma once
#include <stdio.h>

namespace rood_shell {

/* After ImGui::CreateContext: docking on, the layout's ini section. */
void init();
/* The workspace below the menu bar and toolbar (window pixels), every frame the editor shows: the
 * host window and dock space; the default layout when due. */
void frame(float top, float width, float height);
/* The Game panel: a docked window whose content rectangle is the picture's inset. */
void game_panel();
/* The editor is closed (or hidden for a photo): the picture fills the window. */
void closed();
/* Before a tool window's Begin (Cutscene, Room Browser, a plugin's rood.dev.window, ...): into the
 * layout's bottom node the first time it is seen, and again after a Reset layout. */
void dock_tool_window(const char* name);
/* Window > Reset layout: the default layout is rebuilt next frame. */
void reset_layout();
/* Focus a panel by its window name (its tab is selected when docked). */
void focus_window(const char* name);

/* The command palette (Ctrl+Shift+P). */
void palette_open(bool open);
bool palette_shown();
void palette_toggle();
/* Draws the palette (after the tool windows: on top). */
void palette_frame();

/* Look-and-feel values (settings keys editor_shell_left, editor_shell_right, editor_shell_bottom,
 * editor_palette_width, editor_palette_rows), their Details section and RPC graphics keys. */
bool parse_setting(const char* key, const char* rest);
void write_settings(FILE* f);
void settings_panel();

} // namespace rood_shell

extern "C" {
/* The look values (C names: dev_rpc.c's graphics keys): fractions of the workspace, the palette's
 * width in font heights and its rows. */
extern float pc_editor_shell_left, pc_editor_shell_right, pc_editor_shell_bottom, pc_editor_palette_width;
extern float pc_editor_palette_rows;
/* RPC editor_shell (dev_rpc.c): params JSON {action "state" | "reset" | "palette" | "window" | "save_ini",
 * open, name, query}; replies the layout's state. */
int pc_editor_shell_rpc(const char* params, char* out, int size);
}
