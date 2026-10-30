// The editor's command registry: see editor_commands.h.
#include "editor_commands.h"
#include "light_prefabs.h" /* prefab::Json: the RPC's params */

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <cstring>

namespace rood_commands {
namespace {
std::vector<Command>& commands()
{
    static auto* list = new std::vector<Command>();
    return *list;
}

std::string lower(const std::string& s)
{
    std::string out = s;
    for (char& c : out)
        c = (char)std::tolower((unsigned char)c);
    return out;
}

std::string quoted(const std::string& s)
{
    std::string out = "\"";
    for (unsigned char c : s) {
        if (c == '"' || c == '\\')
            out += '\\', out += (char)c;
        else if (c < 0x20) {
            char buf[8];
            snprintf(buf, sizeof buf, "\\u%04x", c);
            out += buf;
        } else
            out += (char)c;
    }
    return out + "\"";
}

std::string describe(const Command& c)
{
    return "{\"id\":" + quoted(c.id) + ",\"title\":" + quoted(c.title) + ",\"category\":" + quoted(c.category)
        + ",\"shortcut\":" + quoted(c.shortcut) + ",\"enabled\":" + (!c.enabled || c.enabled() ? "true" : "false")
        + ",\"checked\":" + (c.checked ? (c.checked() ? "true" : "false") : "null")
        + ",\"plugin\":" + (c.owner ? "true" : "false") + "}";
}
} // namespace

void add(const Command& c)
{
    for (Command& x : commands())
        if (x.id == c.id) {
            x = c;
            return;
        }
    commands().push_back(c);
}

bool remove(const std::string& id)
{
    auto& list = commands();
    for (auto it = list.begin(); it != list.end(); ++it)
        if (it->id == id) {
            list.erase(it);
            return true;
        }
    return false;
}

void remove_owner(const void* owner)
{
    auto& list = commands();
    list.erase(std::remove_if(list.begin(), list.end(), [owner](const Command& c) { return c.owner == owner; }),
        list.end());
}

const std::vector<Command>& list() { return commands(); }

const Command* find(const std::string& id)
{
    for (const Command& c : commands())
        if (c.id == id)
            return &c;
    return nullptr;
}

bool run(const std::string& id)
{
    const Command* c = find(id);
    if (!c || (c->enabled && !c->enabled()) || !c->run)
        return false;
    std::function<void()> fn = c->run; /* a copy: running may register or drop commands */
    fn();
    return true;
}

/* Subsequence match, both sides lower-cased by the caller. Each query character must appear in
 * order; a character at a word start scores 3, one right after the previous match 2, any other 1;
 * a match that starts at the text's first character gets 4 more. The highest-scoring alignment is
 * found greedily (earliest word start, else the next occurrence), good enough for a palette. */
int score(const char* query, const char* text)
{
    if (!*query)
        return 0;
    int total = 0, pos = 0, last = -2;
    int n = (int)strlen(text);
    for (const char* q = query; *q; q++) {
        if (*q == ' ')
            continue;
        int at = -1;
        /* A word start first (the first letter, or one after a space or punctuation). */
        for (int i = pos; i < n; i++)
            if (text[i] == *q && (i == 0 || !std::isalnum((unsigned char)text[i - 1]))) {
                at = i;
                break;
            }
        int plain = -1;
        for (int i = pos; i < n; i++)
            if (text[i] == *q) {
                plain = i;
                break;
            }
        if (plain < 0)
            return -1;
        /* Keep a run going when the plain match continues the previous one. */
        if (plain == last + 1 && (at < 0 || at != plain))
            at = plain;
        if (at < 0)
            at = plain;
        total += (at == 0 || !std::isalnum((unsigned char)text[at - 1])) ? 3 : at == last + 1 ? 2 : 1;
        if (q == query && at == 0)
            total += 4;
        last = at;
        pos = at + 1;
    }
    return total;
}

std::vector<Match> match(const std::string& query, size_t limit)
{
    std::vector<Match> out;
    std::string q = lower(query);
    const auto& list = commands();
    for (int i = 0; i < (int)list.size(); i++) {
        const Command& c = list[i];
        if (q.empty()) {
            out.push_back({ i, 0 });
            continue;
        }
        /* The title first (it is what the user reads), then category and id. */
        int s = score(q.c_str(), lower(c.title).c_str());
        int s2 = score(q.c_str(), lower(c.category + " " + c.title).c_str());
        int s3 = score(q.c_str(), lower(c.id).c_str());
        int best = std::max(s + (s >= 0 ? 2 : 0), std::max(s2, s3 - 1));
        if (best >= 0)
            out.push_back({ i, best });
    }
    if (!q.empty())
        std::stable_sort(out.begin(), out.end(), [](const Match& a, const Match& b) { return a.score > b.score; });
    if (limit && out.size() > limit)
        out.resize(limit);
    return out;
}

} // namespace rood_commands

extern "C" int pc_editor_command_rpc(const char* params_text, char* out, int size)
{
    using prefab::Json;
    using namespace rood_commands;
    Json params;
    std::string error;
    if (!prefab::json_parse(params_text && *params_text ? params_text : "{}", params, &error) || params.type != Json::Object) {
        snprintf(out, size, "params: %s", error.empty() ? "expected an object" : error.c_str());
        return -1;
    }
    const Json* a = params.get("action");
    std::string action = a && a->type == Json::String ? a->string : "list";
    const Json* idj = params.get("id");
    std::string id = idj && idj->type == Json::String ? idj->string : "";
    const Json* qj = params.get("query");
    std::string query = qj && qj->type == Json::String ? qj->string : "";
    std::string reply;
    if (action == "run") {
        const Command* c = find(id);
        if (!c) {
            snprintf(out, size, "editor_command: no command '%s'", id.c_str());
            return -1;
        }
        bool ran = run(id);
        reply = "{\"ran\":" + std::string(ran ? "true" : "false") + ",\"command\":" + describe(*c) + "}";
    } else if (action == "list" || action == "query") {
        std::vector<Match> m = match(query);
        reply = "{\"count\":" + std::to_string(list().size()) + ",\"commands\":[";
        for (size_t i = 0; i < m.size(); i++)
            reply += (i ? "," : "") + describe(list()[m[i].index]);
        reply += "]}";
    } else {
        snprintf(out, size, "editor_command: action is list, query or run");
        return -1;
    }
    if ((int)reply.size() >= size) {
        snprintf(out, size, "editor_command: the reply is too long (%zu bytes)", reply.size());
        return -1;
    }
    memcpy(out, reply.c_str(), reply.size() + 1);
    return 0;
}
