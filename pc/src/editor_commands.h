// The editor's command registry (pc/docs/plans/2026-10-30-editor-shell-design.md, goal 5): one
// list of named actions the command palette (Ctrl+Shift+P), the Window menu, RPC editor_command and
// plugins (rood.dev.command) share. A command has an id ("window.room_browser"), a title, a category
// and an optional shortcut label; run() does it; enabled() (optional) greys it out.
#pragma once
#include <functional>
#include <string>
#include <vector>

namespace rood_commands {

struct Command {
    std::string id, title, category, shortcut;
    std::function<void()> run;
    std::function<bool()> enabled; // empty: always
    std::function<bool()> checked; // empty: not a toggle; else its state (a tick in the palette)
    const void* owner = nullptr;   // remove_owner drops every command registered with it (a plugin)
};

/* Adds or replaces (by id). */
void add(const Command& c);
bool remove(const std::string& id);
void remove_owner(const void* owner);
const std::vector<Command>& list();
const Command* find(const std::string& id);
/* Runs a command; false when unknown or disabled. */
bool run(const std::string& id);

/* The palette's search: a case-insensitive subsequence match over "category title id", scored
 * (word starts and runs score higher); an empty query lists everything in registration order. */
struct Match {
    int index; /* into list() */
    int score;
};
std::vector<Match> match(const std::string& query, size_t limit = 0);
int score(const char* query, const char* text); /* < 0: no match (the probe tests it) */

} // namespace rood_commands

extern "C" {
/* RPC editor_command (dev_rpc.c): params JSON {action "list" | "run" | "query", id, query}. */
int pc_editor_command_rpc(const char* params, char* out, int size);
}
