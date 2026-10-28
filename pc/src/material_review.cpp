// The Material review (pc/docs/Materials.md, "Reviewing in the game"):
// Window > Material review (or Details > Material > Material review...) and
// RPC material_review. It reads the material rollout's proposals
// (pc/tools/material_rollout.py report: proposals.json, one per palette or
// 15-bit texture) and walks them in the game: each proposal's rooms with Go
// (a warp, without enemies or scripts by default, also into rooms no door
// leads to), its preset previewed in place on the surfaces it covers (a
// temporary entry, never saved: materials::set_preview), before and after,
// a highlight that pulses the palette's surfaces (emissive::set_highlight),
// Focus (the free camera framed on the largest cluster of those surfaces in
// the room, going to the proposal's top room first when the player is in
// none of its rooms), Isolate (everything else dimmed and greyed:
// emissive::set_isolate), and the decision: Accept writes ONE entry (the
// palette, or the texture, scoped to the proposal's rooms) into the user
// material layer (materials.json, as Details > Material saves), review
// "accepted"; Reject is recorded; Undo puts the last decision back (and the
// user layer's entry as it was). Decisions come from buttons or Ctrl chords
// only, never a bare letter (the camera flies with WASD). The decisions live
// in review_state.json beside proposals.json (a review
// material_rollout_apply.py reads), so a session resumes where it stopped.
// The window also exists in Lua (pc/plugins/rood.material_review, on RPC
// material_review alone): while that plugin is on it takes this window's
// place (rood.dev.window{replaces}) and this one draws nothing.
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <algorithm>
#include <filesystem>
#include <map>
#include <string>
#include <vector>

#include <SDL3/SDL.h>

#include "imgui.h"
#include "dev_state.h"
#include "emissive.h"
#include "emissive_internal.h"
#include "materials.h"
#include "material_editor.h"
#include "room_warp.h"

using prefab::Json;

extern "C" int pc_overlay_set_details_tab(const char* name);
extern "C" int pc_editor_active(void);
extern "C" void pc_editor_toggle(void);
extern "C" int pc_editor_flying(void);
extern "C" int pc_cutscene_camera_flying(void);
extern "C" float pc_editor_look_at(const float from[3], const float at[3]);
extern "C" int pc_editor_camera(int set, float position[3], float* yaw_degrees, float* pitch_degrees);
extern "C" void pc_editor_set_focus(int fixed, const float point[3]);
extern "C" int pc_rpc_is_paused(void);
extern "C" void pc_rpc_request_step(long vsyncs);

bool pc_material_review_open;
/* The Lua window may take its place (pc/plugins/rood.material_review: rood.dev.window{replaces}). */
extern "C" void pc_lua_dev_replaceable(const char* name, bool* open) __attribute__((weak));
static struct ReplaceableReview {
    ReplaceableReview()
    {
        if (pc_lua_dev_replaceable)
            pc_lua_dev_replaceable("material_review", &pc_material_review_open);
    }
} replaceable_review;

namespace {

const char* const PREVIEW_ID = "review"; /* the preview entry's id (never saved) */

struct Room {
    int zone = 0, room = 0;
    float share = 0;
    std::string name;
};
struct Proposal {
    std::string id, kind, clut, key, stable;
    int w = 0, h = 0;
    float coverage = 0;
    std::vector<Room> rooms;
    std::string preset, confidence, reason;
    std::vector<std::string> alternatives, in_catalog;
};
struct Decision {
    std::string decision; /* "accept" or "reject" */
    std::string preset, entry;
};

/* The tunables (the state file's "settings", the window, RPC). */
struct Settings {
    float highlight_rgb[3] = { 1.0f, 0.3f, 1.0f };
    float highlight_strength = 1.0f; /* the pulse's peak, 0..4 (x the colour) */
    float highlight_rate = 1.5f; /* pulses a second (0: steady) */
    float highlight_floor = 0.15f; /* the pulse's low point, a share of its peak */
    bool highlight_flat = true; /* the colour itself (else the texel's own colour x it) */
    float isolate_dim = 0.75f, isolate_grey = 0.85f; /* Isolate: what everything else loses (0..1) */
    float focus_margin = 1.3f; /* Focus: the cluster's radius x this fills the view's height */
    float focus_join = 160; /* Focus: surfaces closer than this (world units) are one cluster */
    float focus_view = 0.4f; /* Focus: 0 along the surfaces' normal, 1 from the player's side */
    float focus_min = 250, focus_max = 2400; /* Focus: the camera's distance (world units) */
    bool focus_cut = true; /* Focus: the editor's cut to focus aims at the surfaces (while open) */
    bool enemies = false, scripts = false; /* Go: the rooms as the survey saw them */
    bool advance = true; /* to the next undecided proposal after a decision */
    bool auto_go = false; /* selecting a proposal goes to its top room unless already in one of its rooms */
};

std::string proposals_path; /* "" until the first load: $ROOD_MATERIAL_REVIEW, else the rollout's */
char path_buffer[512];
std::vector<Proposal> proposals;
std::map<std::string, Decision> decisions; /* by Proposal::stable */
Settings settings;
std::string load_error, status_line;
int selected = -1; /* index into proposals */
materials::Entry current; /* the selected proposal's entry as it would be accepted (tuned) */
bool preview_on = true, highlight_on = false, isolate_on = false, active = false;
float pulse_at = -1; /* the pulse held at this point of its wave (0..1; RPC, tests), -1: running */
bool keys_focused; /* the window had the keyboard at its last frame */
int keys_frame = -10; /* ImGui's frame of that */
bool focus_window; /* RPC open {focus}: the window takes the keyboard next frame */
/* The last decisions, newest last (Undo): what each changed, to put back. */
struct Undo {
    std::string stable, what;
    bool had = false; /* the proposal had a decision before */
    Decision before;
    bool had_entry = false; /* the user layer had its entry before */
    materials::Entry entry;
};
std::vector<Undo> undo_stack;
/* Focus: the last framing, and one waiting for a Go to arrive. */
struct Focus {
    bool ok = false;
    int triangles = 0, cluster = 0, clusters = 0;
    float centre[3] = { 0, 0, 0 }, eye[3] = { 0, 0, 0 }, radius = 0, distance = 0;
    std::string why;
} last_focus;
bool focus_pending;
int focus_zone = -1, focus_room = -1;
uint64_t focus_deadline;
/* The filters. */
int filter_status = 0; /* 0 all, 1 undecided, 2 accepted, 3 rejected */
std::string filter_preset; /* "" all */
int filter_confidence = 0; /* 0 all, 1 high, 2 medium, 3 low */
int filter_zone = -1;
bool scroll_to_selected; /* the list shows the selection once after it changed */

const char* const status_names[] = { "all", "undecided", "accepted", "rejected" };
const char* const confidence_names[] = { "all", "high", "medium", "low" };

std::string default_path()
{
    const char* e = getenv("ROOD_MATERIAL_REVIEW");
    return e && *e ? e : "pc/build/material_rollout/proposals.json";
}
std::string state_path()
{
    std::filesystem::path p(proposals_path);
    return (p.parent_path() / "review_state.json").string();
}
bool read_text(const std::string& path, std::string& text)
{
    FILE* f = fopen(path.c_str(), "rb");
    if (!f) return false;
    char buf[65536];
    size_t n;
    text.clear();
    while ((n = fread(buf, 1, sizeof buf, f))) text.append(buf, n);
    fclose(f);
    return true;
}
std::string str_of(const Json& j, const char* name)
{
    const Json* v = j.get(name);
    return v && v->type == Json::String ? v->string : "";
}
double num_of(const Json& j, const char* name, double fallback = 0)
{
    const Json* v = j.get(name);
    return v && v->type == Json::Number ? v->number : fallback;
}
bool preset_known(const std::string& name)
{
    if (name == "none") return true;
    for (const auto& p : materials::catalog_presets())
        if (p.first == name) return true;
    return false;
}

/* ---------------------------------------------------------------- the state file */

Json settings_json()
{
    Json s = Json::object();
    Json rgb = Json::array();
    for (float c : settings.highlight_rgb) rgb.items.push_back(Json::num(std::round(c * 1000) / 1000));
    s.set("highlight_rgb", rgb);
    s.set("highlight_strength", Json::num(settings.highlight_strength));
    s.set("highlight_rate", Json::num(settings.highlight_rate));
    s.set("highlight_floor", Json::num(settings.highlight_floor));
    s.set("highlight_flat", Json::boolean_(settings.highlight_flat));
    s.set("isolate_dim", Json::num(settings.isolate_dim));
    s.set("isolate_grey", Json::num(settings.isolate_grey));
    s.set("focus_margin", Json::num(settings.focus_margin));
    s.set("focus_join", Json::num(settings.focus_join));
    s.set("focus_view", Json::num(settings.focus_view));
    s.set("focus_min", Json::num(settings.focus_min));
    s.set("focus_max", Json::num(settings.focus_max));
    s.set("focus_cut", Json::boolean_(settings.focus_cut));
    s.set("enemies", Json::boolean_(settings.enemies));
    s.set("scripts", Json::boolean_(settings.scripts));
    s.set("advance", Json::boolean_(settings.advance));
    s.set("auto_go", Json::boolean_(settings.auto_go));
    return s;
}
/* (`saved`: from a state file, which before highlight_flat had a strength x
 * the texel's colour: then the strength is not read) */
void settings_from(const Json& s, bool saved = false)
{
    if (const Json* rgb = s.get("highlight_rgb"); rgb && rgb->type == Json::Array && rgb->items.size() == 3)
        for (int k = 0; k < 3; k++)
            settings.highlight_rgb[k] = std::clamp((float)rgb->items[k].number, 0.0f, 1.0f);
    if (const Json* v = s.get("highlight_strength"); v && v->type == Json::Number && (!saved || s.get("highlight_flat")))
        settings.highlight_strength = std::clamp((float)v->number, 0.0f, 4.0f);
    struct {
        const char* name;
        float* value;
        float lo, hi;
    } numbers[] = { { "highlight_rate", &settings.highlight_rate, 0, 10 },
        { "highlight_floor", &settings.highlight_floor, 0, 1 }, { "isolate_dim", &settings.isolate_dim, 0, 1 },
        { "isolate_grey", &settings.isolate_grey, 0, 1 }, { "focus_margin", &settings.focus_margin, 0.5f, 4 },
        { "focus_join", &settings.focus_join, 8, 2048 }, { "focus_view", &settings.focus_view, 0, 1 },
        { "focus_min", &settings.focus_min, 16, 8192 }, { "focus_max", &settings.focus_max, 16, 16384 } };
    for (const auto& n : numbers)
        if (const Json* v = s.get(n.name); v && v->type == Json::Number)
            *n.value = std::clamp((float)v->number, n.lo, n.hi);
    bool* flags[] = { &settings.enemies, &settings.scripts, &settings.advance, &settings.auto_go,
        &settings.highlight_flat, &settings.focus_cut };
    const char* names[] = { "enemies", "scripts", "advance", "auto_go", "highlight_flat", "focus_cut" };
    for (int k = 0; k < 6; k++)
        if (const Json* v = s.get(names[k]); v && v->type == Json::Bool) *flags[k] = v->boolean;
}
const Proposal* by_stable(const std::string& stable)
{
    for (const Proposal& p : proposals)
        if (p.stable == stable) return &p;
    return nullptr;
}
/* review_state.json: a review in material_rollout_apply.py's format (kind
 * material_rollout_review, decisions accept / reject), plus each decision's
 * stable key and entry, the settings and the selection. */
bool save_state(std::string* error)
{
    Json j = Json::object();
    j.set("format", Json::num(1));
    j.set("kind", Json::str("material_rollout_review"));
    j.set("about", Json::str("The in-game Material review's decisions (Window > Material review); accepted ones are "
                             "already in the user material layer. material_rollout_apply.py reads it too."));
    j.set("settings", settings_json());
    if (selected >= 0) j.set("selected", Json::str(proposals[(size_t)selected].stable));
    Json list = Json::array();
    for (const auto& kv : decisions) {
        const Proposal* p = by_stable(kv.first);
        Json d = Json::object();
        d.set("stable", Json::str(kv.first));
        d.set("decision", Json::str(kv.second.decision));
        d.set("preset", Json::str(kv.second.preset));
        if (!kv.second.entry.empty()) d.set("entry", Json::str(kv.second.entry));
        if (p) {
            d.set("id", Json::str(p->id));
            d.set("kind", Json::str(p->kind));
            d.set("clut", Json::str(p->clut));
            if (p->kind == "texture") {
                d.set("key", Json::str(p->key));
                Json size = Json::array();
                size.items.push_back(Json::num(p->w));
                size.items.push_back(Json::num(p->h));
                d.set("size", size);
            }
            d.set("proposed", Json::str(p->preset));
            d.set("changed", Json::boolean_(p->preset != kv.second.preset));
            d.set("scope", Json::str("rooms"));
            Json rooms = Json::array();
            Json names = Json::object();
            for (const Room& r : p->rooms) {
                Json pair = Json::array();
                pair.items.push_back(Json::num(r.zone));
                pair.items.push_back(Json::num(r.room));
                rooms.items.push_back(pair);
                if (!r.name.empty()) names.set((std::to_string(r.zone) + "-" + std::to_string(r.room)).c_str(), Json::str(r.name));
            }
            d.set("rooms", rooms);
            d.set("room_names", names);
            d.set("coverage", Json::num(p->coverage));
        }
        list.items.push_back(d);
    }
    j.set("decisions", list);
    std::string path = state_path(), temp = path + ".tmp";
    FILE* f = fopen(temp.c_str(), "wb");
    if (!f) {
        if (error) *error = "cannot write " + temp;
        return false;
    }
    std::string text = prefab::json_write(j, 1) + "\n";
    bool ok = fwrite(text.data(), 1, text.size(), f) == text.size();
    ok = fclose(f) == 0 && ok;
    std::error_code ec;
    if (ok) std::filesystem::rename(temp, path, ec);
    if (!ok || ec) {
        remove(temp.c_str());
        if (error) *error = "cannot write " + path;
        return false;
    }
    return true;
}
void load_state(std::string* selected_stable)
{
    decisions.clear();
    std::string text;
    if (!read_text(state_path(), text)) return;
    Json j;
    std::string error;
    if (!prefab::json_parse(text.c_str(), j, &error) || j.type != Json::Object) {
        status_line = state_path() + ": " + error + " (decisions not read)";
        return;
    }
    if (const Json* s = j.get("settings"); s && s->type == Json::Object) settings_from(*s, true);
    if (selected_stable) *selected_stable = str_of(j, "selected");
    if (const Json* list = j.get("decisions"); list && list->type == Json::Array)
        for (const Json& d : list->items) {
            std::string stable = str_of(d, "stable"), decision = str_of(d, "decision");
            if (stable.empty() || (decision != "accept" && decision != "reject")) continue;
            decisions[stable] = { decision, str_of(d, "preset"), str_of(d, "entry") };
        }
}

/* ---------------------------------------------------------------- proposals */

bool load(const std::string& path)
{
    proposals.clear();
    decisions.clear();
    undo_stack.clear();
    focus_pending = false;
    selected = -1;
    proposals_path = path;
    snprintf(path_buffer, sizeof path_buffer, "%s", path.c_str());
    std::string text, error;
    Json j;
    if (!read_text(path, text)) {
        load_error = "cannot read " + path + " (run pc/tools/material_rollout.py report)";
        return false;
    }
    if (!prefab::json_parse(text.c_str(), j, &error) || j.type != Json::Object) {
        load_error = path + ": " + error;
        return false;
    }
    const Json* list = j.get("proposals");
    if (!list || list->type != Json::Array) {
        load_error = path + ": no proposals";
        return false;
    }
    for (const Json& q : list->items) {
        if (q.type != Json::Object) continue;
        Proposal p;
        p.id = str_of(q, "id"), p.kind = str_of(q, "kind"), p.clut = str_of(q, "clut"), p.key = str_of(q, "key");
        if (const Json* size = q.get("size"); size && size->type == Json::Array && size->items.size() == 2)
            p.w = (int)size->items[0].number, p.h = (int)size->items[1].number;
        p.coverage = (float)num_of(q, "coverage");
        p.preset = str_of(q, "preset"), p.confidence = str_of(q, "confidence"), p.reason = str_of(q, "reason");
        if (const Json* a = q.get("alternatives"); a && a->type == Json::Array)
            for (const Json& x : a->items) if (x.type == Json::String) p.alternatives.push_back(x.string);
        if (const Json* a = q.get("in_catalog"); a && a->type == Json::Array)
            for (const Json& x : a->items) if (x.type == Json::String) p.in_catalog.push_back(x.string);
        const Json* names = q.get("room_names");
        if (const Json* rooms = q.get("rooms"); rooms && rooms->type == Json::Object)
            for (const auto& kv : rooms->members) {
                Room r;
                if (sscanf(kv.first.c_str(), "%d-%d", &r.zone, &r.room) != 2) continue;
                r.share = (float)kv.second.number;
                if (names && names->type == Json::Object) r.name = str_of(*names, kv.first.c_str());
                p.rooms.push_back(r);
            }
        std::sort(p.rooms.begin(), p.rooms.end(), [](const Room& a, const Room& b) { return a.share > b.share; });
        if (p.kind == "palette") {
            if (p.clut.size() != 10) continue;
            p.stable = "pal:" + p.clut;
        } else {
            if (p.key.size() != 10 || p.w < 1 || p.h < 1) continue;
            p.stable = "tex:" + p.key + "-" + std::to_string(p.w) + "x" + std::to_string(p.h);
        }
        if (p.rooms.empty()) continue;
        proposals.push_back(p);
    }
    std::stable_sort(proposals.begin(), proposals.end(),
        [](const Proposal& a, const Proposal& b) { return a.coverage > b.coverage; });
    load_error.clear();
    std::string stable;
    load_state(&stable);
    for (size_t i = 0; i < proposals.size(); i++)
        if (proposals[i].stable == stable) selected = (int)i;
    status_line = std::to_string(proposals.size()) + " proposals from " + path + ", " + std::to_string(decisions.size())
        + " decided (" + state_path() + ")";
    return true;
}
void ensure_loaded()
{
    if (proposals_path.empty()) load(default_path());
}

std::string entry_id(const Proposal& p)
{
    return p.kind == "palette" ? "R" + p.clut : "R" + p.key + "-" + std::to_string(p.w) + "x" + std::to_string(p.h);
}
std::string rooms_text(const Proposal& p, size_t limit)
{
    std::string out;
    for (size_t i = 0; i < p.rooms.size() && i < limit; i++)
        out += (i ? ", " : "") + std::to_string(p.rooms[i].zone) + "/" + std::to_string(p.rooms[i].room);
    if (p.rooms.size() > limit) out += ", ...";
    return out;
}
/* The entry accepting the proposal writes (with the preset, untuned). */
materials::Entry entry_for(const Proposal& p, const std::string& preset)
{
    materials::Entry e;
    e.id = entry_id(p);
    std::string title = preset;
    if (!title.empty()) title[0] = (char)toupper((unsigned char)title[0]);
    e.name = title + " (review " + p.id + ")";
    char where[240];
    snprintf(where, sizeof where, "material review %s: %s; %d rooms: %s", p.id.c_str(),
        p.kind == "palette" ? ("palette " + p.clut).c_str() : ("texture " + p.key).c_str(), (int)p.rooms.size(),
        rooms_text(p, 6).c_str());
    e.where = where;
    if (p.kind == "palette")
        e.clut = p.clut;
    else
        e.key = p.key, e.w = p.w, e.h = p.h;
    e.zone = p.rooms[0].zone, e.room = p.rooms[0].room;
    if (p.rooms.size() > 1)
        for (const Room& r : p.rooms) e.rooms.push_back({ r.zone, r.room });
    e.preset = preset == "none" ? "" : preset;
    for (const auto& pr : materials::catalog_presets())
        if (pr.first == preset) e.value = pr.second;
    e.explicit_fields = 0;
    e.review = "accepted";
    e.user = true;
    return e;
}
const materials::Entry* user_entry(const std::string& id, std::vector<materials::Entry>& all)
{
    all = materials::catalog_entries();
    for (const materials::Entry& e : all)
        if (e.id == id && e.user && !e.preview) return &e;
    return nullptr;
}
/* The selected proposal's working entry: the accepted one from the user
 * layer (to fine-tune it further), else the proposal's preset. */
void reset_current()
{
    if (selected < 0) return;
    const Proposal& p = proposals[(size_t)selected];
    auto d = decisions.find(p.stable);
    std::vector<materials::Entry> all;
    const materials::Entry* mine = user_entry(entry_id(p), all);
    if (mine && d != decisions.end() && d->second.decision == "accept") {
        current = *mine;
        current.preview = false;
        return;
    }
    std::string preset = d != decisions.end() && !d->second.preset.empty() ? d->second.preset : p.preset;
    current = entry_for(p, preset_known(preset) ? preset : "none");
}
std::string current_preset() { return current.preset.empty() ? "none" : current.preset; }

/* The preview (materials::set_preview) and the highlight follow the window. */
std::string applied_preview = "-"; /* what set_preview has now ("": nothing): set only on a change */
void preview(const std::vector<materials::Entry>& entries)
{
    std::string text;
    for (const materials::Entry& e : entries) text += materials::entry_json(e);
    if (text == applied_preview) return; /* (every change re-matches the textures in view) */
    applied_preview = text;
    materials::set_preview(entries);
}
void apply_preview()
{
    if (!active || selected < 0) {
        preview({});
        return;
    }
    materials::Entry e = current;
    e.id = PREVIEW_ID;
    if (!preview_on || current_preset() == "none") { /* before: the surfaces without a material */
        e.preset.clear();
        e.value = materials::Surface();
        e.explicit_fields = 1 | 2 | 4 | 8 | 16;
    }
    preview({ e });
}
/* The highlight pulses (its strength now), Isolate marks the same surfaces
 * (without the highlight: marked, nothing glows) and dims everything else. */
void apply_highlight(float strength)
{
    const float* rgb = settings.highlight_rgb;
    bool marked = active && (highlight_on || isolate_on) && selected >= 0;
    if (!marked) {
        emissive::set_highlight("", "", 0, 0, rgb, 0, false);
        emissive::set_isolate(0, 0);
        return;
    }
    const Proposal& p = proposals[(size_t)selected];
    emissive::set_highlight(p.kind == "palette" ? p.clut : "", p.kind == "palette" ? "" : p.key, p.w, p.h, rgb,
        highlight_on ? strength : 0, settings.highlight_flat);
    emissive::set_isolate(isolate_on ? settings.isolate_dim : 0, isolate_on ? settings.isolate_grey : 0);
}
/* Whether the player is in one of the proposal's rooms (its index there, else -1). */
int room_index(const Proposal& p)
{
    int z = -1, r = -1;
    emissive::current_room(&z, &r);
    for (size_t i = 0; i < p.rooms.size(); i++)
        if (p.rooms[i].zone == z && p.rooms[i].room == r) return (int)i;
    return -1;
}

bool passes(const Proposal& p)
{
    auto d = decisions.find(p.stable);
    int status = d == decisions.end() ? 1 : d->second.decision == "accept" ? 2 : 3;
    if (filter_status && filter_status != status) return false;
    if (!filter_preset.empty()) {
        std::string preset = d != decisions.end() && !d->second.preset.empty() ? d->second.preset : p.preset;
        if (preset != filter_preset) return false;
    }
    if (filter_confidence && p.confidence != confidence_names[filter_confidence]) return false;
    if (filter_zone >= 0) {
        bool any = false;
        for (const Room& r : p.rooms) any |= r.zone == filter_zone;
        if (!any) return false;
    }
    return true;
}
std::vector<int> visible()
{
    std::vector<int> out;
    for (size_t i = 0; i < proposals.size(); i++)
        if (passes(proposals[i])) out.push_back((int)i);
    return out;
}

bool go_room(int zone, int room, std::string* why)
{
    char text[200] = "";
    if (!pc_room_browser_go_anywhere(zone, room, settings.enemies, settings.scripts, text, sizeof text)) {
        if (why) *why = text[0] ? text : "the warp was refused";
        return false;
    }
    status_line = "Going to " + std::to_string(zone) + "/" + std::to_string(room);
    return true;
}
/* The proposal's next room after the one the player is in (its top room
 * when the player is in none of them). */
bool go_next_room(std::string* why)
{
    if (selected < 0) {
        if (why) *why = "no proposal selected";
        return false;
    }
    const Proposal& p = proposals[(size_t)selected];
    int z = -1, r = -1;
    emissive::current_room(&z, &r);
    size_t next = 0;
    for (size_t i = 0; i < p.rooms.size(); i++)
        if (p.rooms[i].zone == z && p.rooms[i].room == r) next = (i + 1) % p.rooms.size();
    return go_room(p.rooms[next].zone, p.rooms[next].room, why);
}
void select(int index)
{
    if (index < 0 || index >= (int)proposals.size()) return;
    selected = index;
    scroll_to_selected = true;
    reset_current();
    const Proposal& p = proposals[(size_t)index];
    if (settings.auto_go) {
        int z = -1, r = -1;
        emissive::current_room(&z, &r);
        bool here = false;
        for (const Room& room : p.rooms) here |= room.zone == z && room.room == r;
        std::string why;
        if (!here && !go_room(p.rooms[0].zone, p.rooms[0].room, &why)) status_line = why;
    }
    std::string error;
    save_state(&error);
}
/* Next (+1) or previous (-1) in the filtered list; undecided: the next one without a decision. */
bool step(int dir, bool undecided = false)
{
    std::vector<int> list = visible();
    if (list.empty()) return false;
    int at = -1;
    for (size_t i = 0; i < list.size(); i++)
        if (list[i] == selected) at = (int)i;
    for (size_t n = 0; n < list.size(); n++) {
        at = at < 0 ? (dir > 0 ? 0 : (int)list.size() - 1) : (at + dir + (int)list.size()) % (int)list.size();
        if (!undecided || !decisions.count(proposals[(size_t)list[(size_t)at]].stable)) {
            select(list[(size_t)at]);
            return true;
        }
    }
    return false;
}
/* accept, reject or clear the selected proposal's decision. */
bool decide(const std::string& decision, std::string* error)
{
    if (selected < 0) {
        if (error) *error = "no proposal selected";
        return false;
    }
    const Proposal& p = proposals[(size_t)selected];
    std::string id = entry_id(p);
    std::vector<materials::Entry> all;
    const materials::Entry* mine = user_entry(id, all);
    bool had = mine != nullptr;
    /* What Undo puts back: the decision and the user layer's entry before. */
    Undo u;
    u.stable = p.stable;
    u.what = p.id + (decision == "accept" ? " accepted" : decision == "reject" ? " rejected" : ": decision cleared");
    if (auto d = decisions.find(p.stable); d != decisions.end()) u.had = true, u.before = d->second;
    if (mine) u.had_entry = true, u.entry = *mine;
    if (decision == "accept") {
        if (current_preset() != "none") {
            materials::Entry e = current;
            e.id = id, e.review = "accepted", e.user = true, e.preview = false;
            if (!materials::put_user_entry(e, error)) return false;
        } else if (had && !materials::remove_user_entry(id, error))
            return false;
        decisions[p.stable] = { "accept", current_preset(), current_preset() == "none" ? "" : id };
        status_line = p.id + " accepted (" + current_preset() + ")"
            + (current_preset() == "none" ? std::string(": no entry") : ": " + id + " in " + materials::catalog_user_file());
    } else if (decision == "reject" || decision == "clear") {
        if (had && !materials::remove_user_entry(id, error)) return false;
        if (decision == "reject")
            decisions[p.stable] = { "reject", current_preset(), "" };
        else
            decisions.erase(p.stable);
        status_line = p.id + (decision == "reject" ? " rejected" : ": decision cleared");
    } else {
        if (error) *error = "decision is accept, reject or clear";
        return false;
    }
    undo_stack.push_back(u);
    if (undo_stack.size() > 64) undo_stack.erase(undo_stack.begin());
    if (!save_state(error)) return false;
    if (decision != "clear" && settings.advance)
        step(+1, true);
    else
        reset_current();
    return true;
}
/* Undo the last decision: the proposal's decision and its user-layer entry
 * as they were, and the selection back on it. */
bool undo(std::string* error)
{
    if (undo_stack.empty()) {
        if (error) *error = "nothing to undo";
        return false;
    }
    Undo u = undo_stack.back();
    undo_stack.pop_back();
    int index = -1;
    for (size_t i = 0; i < proposals.size(); i++)
        if (proposals[i].stable == u.stable) index = (int)i;
    if (index < 0) {
        if (error) *error = "the proposal is no longer loaded";
        return false;
    }
    std::string id = entry_id(proposals[(size_t)index]);
    std::vector<materials::Entry> all;
    if (u.had_entry) {
        if (!materials::put_user_entry(u.entry, error)) return false;
    } else if (user_entry(id, all) && !materials::remove_user_entry(id, error))
        return false;
    if (u.had)
        decisions[u.stable] = u.before;
    else
        decisions.erase(u.stable);
    selected = index; /* (not select(): no Go) */
    scroll_to_selected = true;
    reset_current();
    status_line = "Undone: " + u.what;
    return save_state(error);
}
void set_preset(const std::string& preset)
{
    if (selected < 0 || !preset_known(preset)) return;
    materials::Entry e = entry_for(proposals[(size_t)selected], preset);
    current = e;
}

/* ---------------------------------------------------------------- Focus */

/* Frame the selected proposal's surfaces in this room with the free camera:
 * its triangles (emissive::texture_triangles) joined into clusters
 * (vertices closer than focus_join), the largest by area framed (its
 * radius x focus_margin fills the view's height), seen from between the
 * surfaces' normal and the player's side (focus_view). */
bool focus_here(std::string* why)
{
    last_focus = Focus();
    const Proposal& p = proposals[(size_t)selected];
    std::vector<std::array<float, 9>> tris = emissive::texture_triangles(
        p.kind == "palette" ? p.clut : "", p.kind == "palette" ? "" : p.key, p.w, p.h);
    last_focus.triangles = (int)tris.size();
    if (tris.empty()) {
        last_focus.why = "none of its surfaces are in this room's geometry";
        if (why) *why = last_focus.why;
        return false;
    }
    /* Clusters: a union of triangles with vertices within focus_join, by grid cells. */
    size_t n = tris.size();
    std::vector<size_t> parent(n);
    for (size_t i = 0; i < n; i++) parent[i] = i;
    auto root = [&](size_t i) {
        while (parent[i] != i) i = parent[i] = parent[parent[i]];
        return i;
    };
    float join = settings.focus_join;
    std::map<std::array<int, 3>, std::vector<std::pair<size_t, int>>> grid; /* cell -> (triangle, vertex) */
    auto cell_of = [&](const float* v) {
        return std::array<int, 3> { (int)floorf(v[0] / join), (int)floorf(v[1] / join), (int)floorf(v[2] / join) };
    };
    for (size_t i = 0; i < n; i++)
        for (int k = 0; k < 3; k++) grid[cell_of(&tris[i][(size_t)k * 3])].push_back({ i, k });
    for (size_t i = 0; i < n; i++)
        for (int k = 0; k < 3; k++) {
            const float* v = &tris[i][(size_t)k * 3];
            std::array<int, 3> c = cell_of(v);
            for (int dx = -1; dx <= 1; dx++)
                for (int dy = -1; dy <= 1; dy++)
                    for (int dz = -1; dz <= 1; dz++) {
                        auto found = grid.find({ c[0] + dx, c[1] + dy, c[2] + dz });
                        if (found == grid.end()) continue;
                        for (const auto& [j, m] : found->second) {
                            const float* w = &tris[j][(size_t)m * 3];
                            float d2 = (v[0] - w[0]) * (v[0] - w[0]) + (v[1] - w[1]) * (v[1] - w[1])
                                + (v[2] - w[2]) * (v[2] - w[2]);
                            if (d2 <= join * join) parent[root(i)] = root(j);
                        }
                    }
        }
    /* The side the player is on (inside the room), else the free camera's eye. */
    float ref[3] = { 0, 0, 0 };
    struct pc_dev_state st;
    memset(&st, 0, sizeof st);
    if (pc_dev_state) pc_dev_state(&st);
    bool has_ref = st.valid && st.has_player;
    if (has_ref)
        ref[0] = (float)st.x, ref[1] = (float)st.y - 80, ref[2] = (float)st.z;
    else {
        float yaw, pitch;
        has_ref = pc_editor_camera(0, ref, &yaw, &pitch) != 0;
    }
    std::map<size_t, double> area;
    std::vector<double> tri_area(n);
    for (size_t i = 0; i < n; i++) {
        const float* t = tris[i].data();
        float e1[3] = { t[3] - t[0], t[4] - t[1], t[5] - t[2] }, e2[3] = { t[6] - t[0], t[7] - t[1], t[8] - t[2] };
        float c[3] = { e1[1] * e2[2] - e1[2] * e2[1], e1[2] * e2[0] - e1[0] * e2[2], e1[0] * e2[1] - e1[1] * e2[0] };
        tri_area[i] = 0.5 * sqrt((double)c[0] * c[0] + (double)c[1] * c[1] + (double)c[2] * c[2]);
        area[root(i)] += tri_area[i];
    }
    size_t best = root(0);
    for (const auto& kv : area)
        if (kv.second > area[best]) best = kv.first;
    last_focus.clusters = (int)area.size();
    /* Its centre (by area), radius and the area-weighted normal turned to the player's side. */
    double centre[3] = { 0, 0, 0 }, total = 0, normal[3] = { 0, 0, 0 };
    for (size_t i = 0; i < n; i++) {
        if (root(i) != best) continue;
        const float* t = tris[i].data();
        ++last_focus.cluster;
        double a = std::max(tri_area[i], 1e-6);
        for (int k = 0; k < 3; k++) centre[k] += a * (t[k] + t[3 + k] + t[6 + k]) / 3.0;
        total += a;
    }
    for (int k = 0; k < 3; k++) centre[k] /= total;
    float radius = 0;
    for (size_t i = 0; i < n; i++) {
        if (root(i) != best) continue;
        const float* t = tris[i].data();
        float e1[3] = { t[3] - t[0], t[4] - t[1], t[5] - t[2] }, e2[3] = { t[6] - t[0], t[7] - t[1], t[8] - t[2] };
        double c[3] = { e1[1] * e2[2] - e1[2] * e2[1], e1[2] * e2[0] - e1[0] * e2[2], e1[0] * e2[1] - e1[1] * e2[0] };
        double side = has_ref ? (ref[0] - t[0]) * c[0] + (ref[1] - t[1]) * c[1] + (ref[2] - t[2]) * c[2] : 1;
        for (int k = 0; k < 3; k++) normal[k] += side < 0 ? -c[k] : c[k];
        for (int v = 0; v < 3; v++) {
            float d[3] = { t[v * 3] - (float)centre[0], t[v * 3 + 1] - (float)centre[1], t[v * 3 + 2] - (float)centre[2] };
            radius = std::max(radius, sqrtf(d[0] * d[0] + d[1] * d[1] + d[2] * d[2]));
        }
    }
    double nl = sqrt(normal[0] * normal[0] + normal[1] * normal[1] + normal[2] * normal[2]);
    float dir[3] = { 0, -1, 0 }; /* (y down: up) */
    if (nl > 1e-6)
        for (int k = 0; k < 3; k++) dir[k] = (float)(normal[k] / nl);
    if (has_ref) {
        float to[3] = { ref[0] - (float)centre[0], ref[1] - (float)centre[1], ref[2] - (float)centre[2] };
        float tl = sqrtf(to[0] * to[0] + to[1] * to[1] + to[2] * to[2]);
        if (tl > 1e-3f)
            for (int k = 0; k < 3; k++)
                dir[k] = dir[k] * (1 - settings.focus_view) + to[k] / tl * settings.focus_view;
    }
    float dl = sqrtf(dir[0] * dir[0] + dir[1] * dir[1] + dir[2] * dir[2]);
    if (dl < 1e-3f) dir[0] = 0, dir[1] = -1, dir[2] = 0, dl = 1;
    /* The distance that fits the radius in the view's height. */
    if (!pc_editor_active()) pc_editor_toggle(); /* (the free camera's field of view is the game camera's) */
    float fov = pc_editor_look_at(nullptr, nullptr);
    float distance = radius * settings.focus_margin / tanf(fov * 0.5f * 3.14159265f / 180.0f);
    distance = std::clamp(distance, settings.focus_min, std::max(settings.focus_min, settings.focus_max));
    float at[3] = { (float)centre[0], (float)centre[1], (float)centre[2] }, eye[3];
    for (int k = 0; k < 3; k++) eye[k] = at[k] + dir[k] / dl * distance;
    pc_editor_look_at(eye, at);
    if (settings.focus_cut) pc_editor_set_focus(1, at);
    if (pc_rpc_is_paused()) pc_rpc_request_step(2); /* (a paused game draws no frame from the new camera) */
    last_focus.ok = true;
    memcpy(last_focus.centre, at, sizeof at);
    memcpy(last_focus.eye, eye, sizeof eye);
    last_focus.radius = radius, last_focus.distance = distance;
    char text[160];
    snprintf(text, sizeof text, "Focus: %d of its %d triangles here (the largest of %d clusters), %.0f units away",
        last_focus.cluster, last_focus.triangles, last_focus.clusters, distance);
    status_line = text;
    return true;
}
/* Focus: here when the player is in one of the proposal's rooms, else Go to
 * its top room first (the framing follows on arrival: focus_pending). */
bool focus(std::string* why)
{
    if (selected < 0) {
        if (why) *why = "no proposal selected";
        return false;
    }
    const Proposal& p = proposals[(size_t)selected];
    focus_pending = false;
    if (room_index(p) >= 0) return focus_here(why);
    if (!go_room(p.rooms[0].zone, p.rooms[0].room, why)) return false;
    focus_pending = true;
    focus_zone = p.rooms[0].zone, focus_room = p.rooms[0].room;
    focus_deadline = SDL_GetTicks() + 30000;
    status_line = "Going to " + std::to_string(focus_zone) + "/" + std::to_string(focus_room) + ": Focus on arrival";
    return true;
}
/* Each frame: a Focus waiting for its room (and the room's geometry). */
void focus_poll()
{
    if (!focus_pending || selected < 0) return;
    if (SDL_GetTicks() > focus_deadline) {
        focus_pending = false;
        status_line = "Focus: " + (last_focus.why.empty() ? std::string("the room did not arrive") : last_focus.why);
        return;
    }
    if (pc_room_warp_phase && pc_room_warp_phase() != 0) return; /* travelling */
    int z = -1, r = -1;
    emissive::current_room(&z, &r);
    if (z != focus_zone || r != focus_room) return;
    std::string why;
    if (focus_here(&why)) focus_pending = false; /* (else its geometry is not captured yet: again next frame) */
}

/* ---------------------------------------------------------------- the window */

/* The window's keys, while it has the keyboard. Never while the camera
 * flies (the right mouse held: WASD, Q, E move it; the window keeps the
 * keyboard meanwhile), a control is held or a field typed in. Decisions are
 * Ctrl chords only (a bare A accepted while strafing left). */
void keys()
{
    ImGuiIO& io = ImGui::GetIO();
    keys_focused = ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows) && !io.WantTextInput;
    keys_frame = ImGui::GetFrameCount();
    if (!keys_focused || ImGui::IsAnyItemActive()) return;
    if (ImGui::IsMouseDown(ImGuiMouseButton_Right) || pc_editor_flying() || pc_cutscene_camera_flying()) return;
    std::string why;
    if (io.KeyCtrl && !io.KeyAlt && !io.KeyShift) {
        if ((ImGui::IsKeyPressed(ImGuiKey_Enter, false) || ImGui::IsKeyPressed(ImGuiKey_KeypadEnter, false))
            && !decide("accept", &why))
            status_line = why;
        if (ImGui::IsKeyPressed(ImGuiKey_Backspace, false) && !decide("reject", &why)) status_line = why;
        if (ImGui::IsKeyPressed(ImGuiKey_Z, false) && !undo(&why)) status_line = why;
        return;
    }
    if (io.KeyAlt || io.KeyShift || io.KeySuper) return;
    if (ImGui::IsKeyPressed(ImGuiKey_N, false) || ImGui::IsKeyPressed(ImGuiKey_GamepadR1, false)) step(+1);
    if (ImGui::IsKeyPressed(ImGuiKey_P, false) || ImGui::IsKeyPressed(ImGuiKey_GamepadL1, false)) step(-1);
    if (ImGui::IsKeyPressed(ImGuiKey_U, false)) step(+1, true);
    if (ImGui::IsKeyPressed(ImGuiKey_F, false) && !focus(&why)) status_line = why;
    if (ImGui::IsKeyPressed(ImGuiKey_B, false) || ImGui::IsKeyPressed(ImGuiKey_GamepadR2, false)) preview_on = !preview_on;
    if (ImGui::IsKeyPressed(ImGuiKey_H, false) || ImGui::IsKeyPressed(ImGuiKey_GamepadL2, false)) highlight_on = !highlight_on;
    if (ImGui::IsKeyPressed(ImGuiKey_O, false)) isolate_on = !isolate_on;
    if (ImGui::IsKeyPressed(ImGuiKey_G, false) && !go_next_room(&why)) status_line = why;
}
void filters()
{
    ImGui::SetNextItemWidth(ImGui::GetFontSize() * 7);
    ImGui::Combo("##status", &filter_status, status_names, 4);
    ImGui::SameLine();
    ImGui::SetNextItemWidth(ImGui::GetFontSize() * 8);
    if (ImGui::BeginCombo("##preset", filter_preset.empty() ? "every preset" : filter_preset.c_str())) {
        if (ImGui::Selectable("every preset", filter_preset.empty())) filter_preset.clear();
        std::vector<std::string> names = { "none" };
        for (const auto& p : materials::catalog_presets()) names.push_back(p.first);
        for (const std::string& n : names)
            if (ImGui::Selectable(n.c_str(), filter_preset == n)) filter_preset = n;
        ImGui::EndCombo();
    }
    ImGui::SameLine();
    ImGui::SetNextItemWidth(ImGui::GetFontSize() * 6);
    ImGui::Combo("##confidence", &filter_confidence, confidence_names, 4);
    ImGui::SameLine();
    ImGui::SetNextItemWidth(ImGui::GetFontSize() * 6);
    ImGui::InputInt("Zone", &filter_zone);
    if (filter_zone < -1) filter_zone = -1;
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_ForTooltip)) ImGui::SetTooltip("-1: every zone");
}
void proposal_list()
{
    std::vector<int> list = visible();
    int undecided = 0, accepted = 0, rejected = 0;
    for (const Proposal& p : proposals) {
        auto d = decisions.find(p.stable);
        (d == decisions.end() ? undecided : d->second.decision == "accept" ? accepted : rejected)++;
    }
    ImGui::Text("%d shown of %d: %d undecided, %d accepted, %d rejected", (int)list.size(), (int)proposals.size(),
        undecided, accepted, rejected);
    if (ImGui::BeginListBox("##proposals", ImVec2(-1, ImGui::GetTextLineHeightWithSpacing() * 9))) {
        ImGuiListClipper clip;
        clip.Begin((int)list.size());
        while (clip.Step())
            for (int row = clip.DisplayStart; row < clip.DisplayEnd; row++) {
                const Proposal& p = proposals[(size_t)list[(size_t)row]];
                auto d = decisions.find(p.stable);
                const char* mark = d == decisions.end() ? "  " : d->second.decision == "accept" ? "A " : "R ";
                std::string preset = d != decisions.end() && !d->second.preset.empty() ? d->second.preset : p.preset;
                char label[200];
                snprintf(label, sizeof label, "%s%s  %6.2f  %-12s %-6s %3d rooms  %s", mark, p.id.c_str(), p.coverage,
                    preset.c_str(), p.confidence.c_str(), (int)p.rooms.size(),
                    p.rooms[0].name.empty() ? "" : p.rooms[0].name.c_str());
                ImVec4 colour = d == decisions.end() ? ImGui::GetStyleColorVec4(ImGuiCol_Text)
                    : d->second.decision == "accept" ? ImVec4(0.5f, 0.9f, 0.5f, 1) : ImVec4(0.9f, 0.5f, 0.5f, 1);
                ImGui::PushStyleColor(ImGuiCol_Text, colour);
                if (ImGui::Selectable(label, list[(size_t)row] == selected)) select(list[(size_t)row]);
                ImGui::PopStyleColor();
            }
        if (scroll_to_selected) { /* (the clipper skips rows out of view: scroll by the row's place) */
            for (size_t row = 0; row < list.size(); row++)
                if (list[row] == selected)
                    ImGui::SetScrollY((float)row * ImGui::GetTextLineHeightWithSpacing()
                        - ImGui::GetTextLineHeightWithSpacing() * 4);
            scroll_to_selected = false;
        }
        ImGui::EndListBox();
    }
}
void proposal_details()
{
    const Proposal& p = proposals[(size_t)selected];
    auto d = decisions.find(p.stable);
    ImGui::SeparatorText(p.id.c_str());
    if (p.kind == "palette")
        ImGui::Text("Palette %s: %.2f rooms' worth of screen", p.clut.c_str(), p.coverage);
    else
        ImGui::Text("Texture %s %d x %d (15-bit): %.2f rooms' worth of screen", p.key.c_str(), p.w, p.h, p.coverage);
    ImGui::TextWrapped("Proposed %s (%s): %s", p.preset.c_str(), p.confidence.c_str(), p.reason.c_str());
    if (!p.alternatives.empty()) {
        std::string alts;
        for (const std::string& a : p.alternatives) alts += (alts.empty() ? "" : ", ") + a;
        ImGui::TextDisabled("Alternatives: %s", alts.c_str());
    }
    if (!p.in_catalog.empty()) {
        std::string ids;
        for (const std::string& a : p.in_catalog) ids += (ids.empty() ? "" : ", ") + a;
        ImGui::TextDisabled("Already in the catalog: %s (a texture's own entry wins over a palette entry)", ids.c_str());
    }
    /* Where the review stands: the room, what the surfaces show, the decision. */
    const ImVec4 green(0.5f, 0.9f, 0.5f, 1), red(0.9f, 0.5f, 0.5f, 1), amber(1.0f, 0.8f, 0.4f, 1);
    int z = -1, r = -1;
    emissive::current_room(&z, &r);
    int here = room_index(p);
    if (here >= 0)
        ImGui::TextColored(green, "Room %02d/%02d %s: one of its %d rooms (%.1f%% of its surfaces' screen)", z, r,
            p.rooms[(size_t)here].name.c_str(), (int)p.rooms.size(), p.rooms[(size_t)here].share * 100);
    else
        ImGui::TextColored(amber, "Room %02d/%02d: not one of its rooms (Focus goes to %02d/%02d first)", z, r,
            p.rooms[0].zone, p.rooms[0].room);
    if (current_preset() == "none")
        ImGui::Text("Showing: the surfaces as they are (the preset is none)");
    else if (preview_on)
        ImGui::TextColored(green, "Showing: PROPOSED %s (B: before)", current_preset().c_str());
    else
        ImGui::TextColored(amber, "Showing: BEFORE, without a material (B: proposed %s)", current_preset().c_str());
    if (d == decisions.end())
        ImGui::Text("Decision: undecided");
    else
        ImGui::TextColored(d->second.decision == "accept" ? green : red, "Decision: %s %s%s%s",
            d->second.decision == "accept" ? "accepted" : "rejected", d->second.preset.c_str(),
            d->second.entry.empty() ? "" : ", entry ", d->second.entry.c_str());
    if (focus_pending)
        ImGui::TextColored(amber, "Focus: going to %02d/%02d...", focus_zone, focus_room);
    /* Finding the surfaces: Focus, the highlight, Isolate. */
    std::string why;
    if (ImGui::Button("Focus (F)") && !focus(&why)) status_line = why;
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_ForTooltip))
        ImGui::SetTooltip("Points the free camera at the largest patch of these surfaces in this room\n"
                          "(going to the proposal's top room first when this is none of its rooms).");
    ImGui::SameLine();
    ImGui::Checkbox("Highlight (H)", &highlight_on);
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_ForTooltip))
        ImGui::SetTooltip("Pulses the surfaces in the highlight colour.");
    ImGui::SameLine();
    ImGui::Checkbox("Isolate (O)", &isolate_on);
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_ForTooltip))
        ImGui::SetTooltip("Dims and greys everything else: only these surfaces keep their colour.");
    if (highlight_on || isolate_on) {
        int cells = emissive::highlight_cells();
        if (cells > 0)
            ImGui::TextDisabled("%d texels marked in view", cells);
        else
            ImGui::TextColored(amber, "None of its surfaces are drawn here: Focus or Go to one of its rooms");
    }
    /* Rooms */
    if (ImGui::BeginTable("##rooms", 3, ImGuiTableFlags_ScrollY | ImGuiTableFlags_RowBg,
            ImVec2(-1, ImGui::GetTextLineHeightWithSpacing() * std::min<size_t>(6, p.rooms.size() + 1)))) {
        ImGui::TableSetupColumn("go", ImGuiTableColumnFlags_WidthFixed);
        ImGui::TableSetupColumn("share", ImGuiTableColumnFlags_WidthFixed);
        ImGui::TableSetupColumn("room");
        for (size_t i = 0; i < p.rooms.size(); i++) {
            const Room& room = p.rooms[i];
            ImGui::TableNextRow();
            ImGui::TableNextColumn();
            ImGui::PushID((int)i);
            if ((int)i == here)
                ImGui::TextColored(green, "here");
            else if (ImGui::SmallButton("Go") && !go_room(room.zone, room.room, &why))
                status_line = why;
            ImGui::PopID();
            ImGui::TableNextColumn();
            ImGui::Text("%5.1f%%", room.share * 100);
            ImGui::TableNextColumn();
            ImGui::Text("%02d/%02d  %s", room.zone, room.room, room.name.c_str());
        }
        ImGui::EndTable();
    }
    if (ImGui::Button("Next room (G)") && !go_next_room(&why)) status_line = why;
    ImGui::SameLine();
    ImGui::Checkbox("Enemies", &settings.enemies);
    ImGui::SameLine();
    ImGui::Checkbox("Scripts", &settings.scripts);
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_ForTooltip))
        ImGui::SetTooltip("Go enters rooms as the survey did: without enemies or scripts unless ticked.");
    ImGui::Checkbox("Proposed material (B: before / after)", &preview_on);
    if (ImGui::TreeNode("Look and behaviour")) {
        bool edited = false;
        ImGui::SeparatorText("Highlight");
        edited |= ImGui::ColorEdit3("Colour", settings.highlight_rgb);
        edited |= ImGui::IsItemDeactivatedAfterEdit();
        ImGui::Checkbox("Flat colour (else the texel's colour x it)", &settings.highlight_flat);
        edited |= ImGui::IsItemDeactivatedAfterEdit();
        ImGui::SliderFloat("Strength", &settings.highlight_strength, 0, 4, "%.2f");
        edited |= ImGui::IsItemDeactivatedAfterEdit();
        ImGui::SliderFloat("Pulses a second", &settings.highlight_rate, 0, 6, "%.1f");
        edited |= ImGui::IsItemDeactivatedAfterEdit();
        ImGui::SliderFloat("Pulse low point", &settings.highlight_floor, 0, 1, "%.2f");
        edited |= ImGui::IsItemDeactivatedAfterEdit();
        ImGui::SeparatorText("Isolate");
        ImGui::SliderFloat("Dim the rest", &settings.isolate_dim, 0, 1, "%.2f");
        edited |= ImGui::IsItemDeactivatedAfterEdit();
        ImGui::SliderFloat("Grey the rest", &settings.isolate_grey, 0, 1, "%.2f");
        edited |= ImGui::IsItemDeactivatedAfterEdit();
        ImGui::SeparatorText("Focus");
        ImGui::SliderFloat("Margin", &settings.focus_margin, 0.5f, 4, "%.2f");
        edited |= ImGui::IsItemDeactivatedAfterEdit();
        ImGui::SliderFloat("Join within", &settings.focus_join, 8, 2048, "%.0f units", ImGuiSliderFlags_Logarithmic);
        edited |= ImGui::IsItemDeactivatedAfterEdit();
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_ForTooltip))
            ImGui::SetTooltip("Surfaces closer than this are one patch; Focus frames the largest patch.");
        ImGui::SliderFloat("View from", &settings.focus_view, 0, 1, "%.2f");
        edited |= ImGui::IsItemDeactivatedAfterEdit();
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_ForTooltip))
            ImGui::SetTooltip("0: straight along the surfaces' normal; 1: from the player's side.");
        ImGui::SliderFloat("Nearest", &settings.focus_min, 16, 8192, "%.0f units", ImGuiSliderFlags_Logarithmic);
        edited |= ImGui::IsItemDeactivatedAfterEdit();
        ImGui::SliderFloat("Farthest", &settings.focus_max, 16, 16384, "%.0f units", ImGuiSliderFlags_Logarithmic);
        edited |= ImGui::IsItemDeactivatedAfterEdit();
        ImGui::Checkbox("Cut to focus aims at the surfaces", &settings.focus_cut);
        edited |= ImGui::IsItemDeactivatedAfterEdit();
        ImGui::SeparatorText("Review");
        ImGui::Checkbox("Next undecided after a decision", &settings.advance);
        edited |= ImGui::IsItemDeactivatedAfterEdit();
        ImGui::Checkbox("Go to a proposal's room when selected", &settings.auto_go);
        edited |= ImGui::IsItemDeactivatedAfterEdit();
        if (edited) {
            std::string error;
            if (!save_state(&error)) status_line = error;
        }
        ImGui::TreePop();
    }
    /* The material: the preset and the fine-tuning (Details > Material's controls). */
    std::vector<std::string> names = { "none" };
    for (const auto& pr : materials::catalog_presets()) names.push_back(pr.first);
    std::string chosen = current_preset();
    if (ImGui::BeginCombo("Proposed preset", chosen.c_str())) {
        for (const std::string& n : names) {
            std::string label = n + (n == p.preset ? "  (proposed)" : "");
            if (ImGui::Selectable(label.c_str(), n == chosen)) set_preset(n);
        }
        ImGui::EndCombo();
    }
    if (chosen != "none" && ImGui::TreeNode("Fine-tune")) {
        materials::Entry e = current;
        if (material_entry_fields(e)) current = e;
        ImGui::TreePop();
    }
    ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.2f, 0.45f, 0.25f, 1));
    if (ImGui::Button("Accept (Ctrl+Enter)") && !decide("accept", &why)) status_line = why;
    ImGui::PopStyleColor();
    ImGui::SameLine();
    ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.5f, 0.22f, 0.22f, 1));
    if (ImGui::Button("Reject (Ctrl+Backspace)") && !decide("reject", &why)) status_line = why;
    ImGui::PopStyleColor();
    ImGui::SameLine();
    if (d != decisions.end() && ImGui::Button("Clear decision") && !decide("clear", &why)) status_line = why;
    if (d != decisions.end() && d->second.decision == "accept" && !d->second.entry.empty()) {
        ImGui::SameLine();
        if (ImGui::Button("Open in Details > Material")) {
            material_editor_select(d->second.entry);
            pc_overlay_set_details_tab("material");
        }
    }
}

} // namespace

namespace {
std::string drawn_look; /* what the picture shows of the review (pc_material_review_redraw) */
bool redraw_wanted;
} // namespace

extern "C" void pc_material_review_frame(void)
{
    bool was = active;
    active = pc_material_review_open;
    if (!active && !was) return;
    if (active) ensure_loaded();
    if (!active) {
        focus_pending = false;
        if (settings.focus_cut && last_focus.ok) pc_editor_set_focus(0, nullptr); /* (the cut's own focus again) */
        last_focus.ok = false;
    }
    focus_poll();
    apply_preview();
    /* The pulse: from highlight_floor to 1 of the strength (pulse_at holds it). */
    float wave = pulse_at >= 0 ? pulse_at
        : settings.highlight_rate > 0
        ? 0.5f + 0.5f * sinf((float)SDL_GetTicks() * 0.001f * settings.highlight_rate * 6.2831853f)
        : 1.0f;
    float strength = settings.highlight_strength * (settings.highlight_floor + (1 - settings.highlight_floor) * wave);
    apply_highlight(strength);
    /* A paused game draws no frame: the picture is drawn again when this changed. */
    char look[160];
    snprintf(look, sizeof look, "%d %d %d %d %.4f %d %.3f %.3f %.3f %.3f %.3f", active, selected, highlight_on, isolate_on,
        strength, settings.highlight_flat, settings.highlight_rgb[0], settings.highlight_rgb[1], settings.highlight_rgb[2],
        settings.isolate_dim, settings.isolate_grey);
    std::string now = look + applied_preview;
    if (now != drawn_look) drawn_look = now, redraw_wanted = true;
}
extern "C" int pc_material_review_redraw(void)
{
    bool wanted = redraw_wanted && pc_rpc_is_paused();
    redraw_wanted = false;
    return wanted;
}
/* (the editor's shortcuts run before the window: its state of the frame before, if it was drawn) */
extern "C" int pc_material_review_keys(void)
{
    return pc_material_review_open && keys_focused && ImGui::GetFrameCount() - keys_frame <= 1;
}

extern "C" void pc_material_review_window(void)
{
    keys_focused = false;
    if (!pc_material_review_open) return;
    ensure_loaded();
    ImGui::SetNextWindowSize(ImVec2(ImGui::GetFontSize() * 46, ImGui::GetFontSize() * 56), ImGuiCond_FirstUseEver);
    if (focus_window) ImGui::SetNextWindowFocus();
    focus_window = false;
    if (!ImGui::Begin("Material review", &pc_material_review_open)) {
        ImGui::End();
        return;
    }
    keys();
    ImGui::TextWrapped("How to review: 1. pick a proposal  2. Focus (F) to see its surfaces  3. compare before / "
                       "after (B)  4. tune the preset  5. Accept or Reject (buttons below)");
    ImGui::SetNextItemWidth(-ImGui::GetFontSize() * 5);
    ImGui::InputText("##path", path_buffer, sizeof path_buffer);
    ImGui::SameLine();
    if (ImGui::Button("Load")) load(path_buffer);
    if (!load_error.empty()) ImGui::TextColored(ImVec4(1, 0.5f, 0.4f, 1), "%s", load_error.c_str());
    filters();
    proposal_list();
    if (selected >= 0)
        proposal_details();
    std::string why;
    ImGui::BeginDisabled(undo_stack.empty());
    std::string undo_label = undo_stack.empty() ? std::string("Undo (Ctrl+Z)") : "Undo " + undo_stack.back().what + " (Ctrl+Z)";
    if (ImGui::Button(undo_label.c_str()) && !undo(&why)) status_line = why;
    ImGui::EndDisabled();
    if (!status_line.empty()) ImGui::TextWrapped("%s", status_line.c_str());
    ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
    ImGui::TextWrapped("Keys %s: N / P next / previous, U next undecided, F focus, B before / after, H highlight, "
                       "O isolate, G next room, Ctrl+Enter accept, Ctrl+Backspace reject, Ctrl+Z undo (pad L1 / R1, "
                       "R2, L2). None while the camera flies (right mouse held).",
        keys_focused ? "(this window has the keyboard)" : "(click this window first)");
    ImGui::PopStyleColor();
    ImGui::End();
}

/* ---------------------------------------------------------------- RPC */

namespace {
Json proposal_json(const Proposal& p, bool full)
{
    Json j = Json::object();
    j.set("index", Json::num((double)(&p - proposals.data())));
    j.set("id", Json::str(p.id));
    j.set("stable", Json::str(p.stable));
    j.set("kind", Json::str(p.kind));
    j.set("clut", Json::str(p.clut));
    if (p.kind == "texture") {
        j.set("key", Json::str(p.key));
        Json size = Json::array();
        size.items.push_back(Json::num(p.w));
        size.items.push_back(Json::num(p.h));
        j.set("size", size);
    }
    j.set("coverage", Json::num(p.coverage));
    j.set("preset", Json::str(p.preset));
    j.set("confidence", Json::str(p.confidence));
    auto d = decisions.find(p.stable);
    j.set("decision", Json::str(d == decisions.end() ? "" : d->second.decision));
    if (d != decisions.end()) {
        j.set("decided_preset", Json::str(d->second.preset));
        j.set("entry", Json::str(d->second.entry));
    }
    j.set("room_count", Json::num((double)p.rooms.size()));
    j.set("first_room", Json::str(p.rooms.empty() ? "" : p.rooms[0].name));
    if (full) {
        j.set("reason", Json::str(p.reason));
        Json alternatives = Json::array(), in_catalog = Json::array();
        for (const std::string& a : p.alternatives) alternatives.items.push_back(Json::str(a));
        for (const std::string& a : p.in_catalog) in_catalog.items.push_back(Json::str(a));
        j.set("alternatives", alternatives);
        j.set("in_catalog", in_catalog);
        Json rooms = Json::array();
        for (const Room& r : p.rooms) {
            Json x = Json::object();
            Json pair = Json::array();
            pair.items.push_back(Json::num(r.zone));
            pair.items.push_back(Json::num(r.room));
            x.set("room", pair);
            x.set("share", Json::num(r.share));
            x.set("name", Json::str(r.name));
            rooms.items.push_back(x);
        }
        j.set("rooms", rooms);
    }
    return j;
}
Json status_json()
{
    Json j = Json::object();
    j.set("open", Json::boolean_(pc_material_review_open));
    j.set("path", Json::str(proposals_path));
    j.set("state", Json::str(proposals_path.empty() ? "" : state_path()));
    j.set("error", Json::str(load_error));
    j.set("count", Json::num((double)proposals.size()));
    j.set("decided", Json::num((double)decisions.size()));
    j.set("preview", Json::boolean_(preview_on));
    j.set("highlight", Json::boolean_(highlight_on));
    j.set("isolate", Json::boolean_(isolate_on));
    j.set("highlight_cells", Json::num(emissive::highlight_cells()));
    j.set("pulse", Json::num(pulse_at));
    j.set("keys", Json::boolean_(pc_material_review_keys() != 0));
    Json undos = Json::array();
    for (auto it = undo_stack.rbegin(); it != undo_stack.rend(); ++it) undos.items.push_back(Json::str(it->what));
    j.set("undo", undos);
    Json f = Json::object();
    f.set("pending", Json::boolean_(focus_pending));
    f.set("ok", Json::boolean_(last_focus.ok));
    f.set("why", Json::str(last_focus.why));
    f.set("triangles", Json::num(last_focus.triangles));
    f.set("cluster", Json::num(last_focus.cluster));
    f.set("clusters", Json::num(last_focus.clusters));
    Json centre = Json::array(), eye = Json::array();
    for (int k = 0; k < 3; k++) {
        centre.items.push_back(Json::num(std::round(last_focus.centre[k] * 10) / 10));
        eye.items.push_back(Json::num(std::round(last_focus.eye[k] * 10) / 10));
    }
    f.set("centre", centre);
    f.set("eye", eye);
    f.set("radius", Json::num(std::round(last_focus.radius * 10) / 10));
    f.set("distance", Json::num(std::round(last_focus.distance * 10) / 10));
    j.set("focus", f);
    j.set("settings", settings_json());
    Json presets = Json::array(); /* the catalog's presets (the preset choice; the Lua window's sliders) */
    for (const auto& pr : materials::catalog_presets()) {
        Json x = Json::object();
        x.set("name", Json::str(pr.first));
        x.set("roughness", Json::num(pr.second.roughness));
        x.set("specular", Json::num(pr.second.specular));
        x.set("metal", Json::num(pr.second.metal));
        x.set("auto_height", Json::boolean_(pr.second.auto_height));
        x.set("bump", Json::num(pr.second.bump));
        presets.items.push_back(x);
    }
    j.set("presets", presets);
    Json filters = Json::object(); /* the window's filters (N / P / U step through what they pass) */
    filters.set("status", Json::str(status_names[filter_status]));
    filters.set("preset", Json::str(filter_preset));
    filters.set("confidence", Json::str(confidence_names[filter_confidence]));
    filters.set("zone", Json::num(filter_zone));
    j.set("filters", filters);
    j.set("status", Json::str(status_line));
    int z = -1, r = -1;
    emissive::current_room(&z, &r);
    Json here = Json::array();
    here.items.push_back(Json::num(z));
    here.items.push_back(Json::num(r));
    j.set("room", here);
    if (selected >= 0) {
        j.set("selected", proposal_json(proposals[(size_t)selected], true));
        j.set("in_room", Json::boolean_(room_index(proposals[(size_t)selected]) >= 0));
        j.set("showing", Json::str(preview_on && current_preset() != "none" ? "proposed" : "before"));
        Json e;
        std::string error;
        prefab::json_parse(materials::entry_json(current).c_str(), e, &error);
        j.set("entry", e);
    }
    return j;
}
int reply(const Json& j, char* out, int size)
{
    std::string text = prefab::json_write(j, 0);
    for (char& c : text)
        if (c == '\n') c = ' '; /* one line per reply */
    if ((int)text.size() >= size) {
        snprintf(out, size, "material_review: the reply is too long (%d bytes)", (int)text.size());
        return -1;
    }
    memcpy(out, text.c_str(), text.size() + 1);
    return 0;
}
int fail(const std::string& m, char* out, int size)
{
    snprintf(out, size, "material_review: %s", m.c_str());
    return -1;
}
bool flag(const Json& j, const char* name, bool* out)
{
    const Json* v = j.get(name);
    if (!v || v->type != Json::Bool) return false;
    *out = v->boolean;
    return true;
}
} // namespace

/* RPC material_review {action: status (default) | open {open, focus: the
 * window takes the keyboard} | load {path} | list {status, preset,
 * confidence, zone, offset, limit} | select {id, stable or index; or next /
 * previous / undecided: true} | preview {on, highlight, isolate, pulse: the
 * pulse held at 0..1 of its wave, -1 running} | preset {preset} | tune
 * {roughness, specular, metal, auto_height, bump} | filters {status, preset,
 * confidence, zone: the window's own, which next / previous / undecided follow} | go {room: [zone, room]}
 * or {next: true} | focus (the status's "focus": pending while it goes to
 * the room first) | decide {decision: accept, reject or clear} | undo |
 * settings {highlight_rgb, highlight_strength, highlight_rate,
 * highlight_floor, highlight_flat, isolate_dim, isolate_grey, focus_margin,
 * focus_join, focus_view, focus_min, focus_max, focus_cut, enemies,
 * scripts, advance, auto_go; save: false applies without writing}}. Opening or any selection makes the window
 * live (the preview, the highlight and Isolate follow it; closing drops
 * them). */
extern "C" int pc_material_review_rpc(const char* params_text, char* out, int size)
{
    Json params;
    std::string error;
    if (!prefab::json_parse(params_text && *params_text ? params_text : "{}", params, &error)
        || params.type != Json::Object)
        return fail("params: " + (error.empty() ? std::string("expected an object") : error), out, size);
    std::string action = str_of(params, "action");
    if (action.empty()) action = "status";
    bool b;
    if (action == "load") {
        std::string path = str_of(params, "path");
        if (!load(path.empty() ? default_path() : path)) return fail(load_error, out, size);
        pc_material_review_open = true;
        pc_material_review_frame();
        return reply(status_json(), out, size);
    }
    ensure_loaded();
    if (action == "status") return reply(status_json(), out, size);
    if (action == "open") {
        pc_material_review_open = !flag(params, "open", &b) || b;
        if (flag(params, "focus", &b) && b) focus_window = true;
        pc_material_review_frame();
        return reply(status_json(), out, size);
    }
    if (action == "list") {
        int saved[3] = { filter_status, filter_confidence, filter_zone };
        std::string saved_preset = filter_preset;
        std::string s = str_of(params, "status");
        for (int k = 0; k < 4; k++) if (s == status_names[k]) filter_status = k;
        std::string c = str_of(params, "confidence");
        for (int k = 0; k < 4; k++) if (c == confidence_names[k]) filter_confidence = k;
        if (params.get("preset")) filter_preset = str_of(params, "preset");
        if (params.get("zone")) filter_zone = (int)num_of(params, "zone", -1);
        std::vector<int> list = visible();
        int offset = (int)num_of(params, "offset", 0), limit = (int)num_of(params, "limit", 50);
        Json j = Json::object();
        j.set("total", Json::num((double)list.size()));
        int counts[3] = { 0, 0, 0 }; /* undecided, accepted, rejected: of every proposal */
        for (const Proposal& p : proposals) {
            auto d = decisions.find(p.stable);
            counts[d == decisions.end() ? 0 : d->second.decision == "accept" ? 1 : 2]++;
        }
        Json tally = Json::object();
        tally.set("undecided", Json::num(counts[0]));
        tally.set("accepted", Json::num(counts[1]));
        tally.set("rejected", Json::num(counts[2]));
        j.set("counts", tally);
        Json items = Json::array();
        for (int i = std::max(0, offset); i < (int)list.size() && i < offset + limit; i++)
            items.items.push_back(proposal_json(proposals[(size_t)list[(size_t)i]], false));
        j.set("proposals", items);
        filter_status = saved[0], filter_confidence = saved[1], filter_zone = saved[2], filter_preset = saved_preset;
        return reply(j, out, size);
    }
    if (action == "filters") { /* the window's filters, kept: {status, preset, confidence, zone} (as list's) */
        std::string s = str_of(params, "status");
        for (int k = 0; k < 4; k++) if (s == status_names[k]) filter_status = k;
        std::string c = str_of(params, "confidence");
        for (int k = 0; k < 4; k++) if (c == confidence_names[k]) filter_confidence = k;
        if (params.get("preset")) filter_preset = str_of(params, "preset");
        if (params.get("zone")) filter_zone = std::max(-1, (int)num_of(params, "zone", -1));
        return reply(status_json(), out, size);
    }
    if (action == "select") {
        pc_material_review_open = true;
        if (flag(params, "next", &b) && b) step(+1);
        else if (flag(params, "previous", &b) && b) step(-1);
        else if (flag(params, "undecided", &b) && b) step(+1, true);
        else {
            int found = -1;
            std::string id = str_of(params, "id"), stable = str_of(params, "stable");
            for (size_t i = 0; i < proposals.size(); i++)
                if ((!id.empty() && proposals[i].id == id) || (!stable.empty() && proposals[i].stable == stable))
                    found = (int)i;
            if (const Json* v = params.get("index"); v && v->type == Json::Number) found = (int)v->number;
            if (found < 0 || found >= (int)proposals.size()) return fail("select: no such proposal", out, size);
            select(found);
        }
        pc_material_review_frame();
        return reply(status_json(), out, size);
    }
    if (action == "undo") {
        if (!undo(&error)) return fail("undo: " + error, out, size);
        pc_material_review_frame();
        return reply(status_json(), out, size);
    }
    if (selected < 0 && action != "settings") return fail(action + ": select a proposal first", out, size);
    if (action == "preview") {
        if (flag(params, "on", &b)) preview_on = b;
        if (flag(params, "highlight", &b)) highlight_on = b;
        if (flag(params, "isolate", &b)) isolate_on = b;
        if (const Json* v = params.get("pulse"); v && v->type == Json::Number)
            pulse_at = v->number < 0 ? -1.0f : std::min((float)v->number, 1.0f);
        pc_material_review_frame();
        return reply(status_json(), out, size);
    }
    if (action == "preset") {
        std::string preset = str_of(params, "preset");
        if (!preset_known(preset)) return fail("no preset " + preset, out, size);
        set_preset(preset);
        pc_material_review_frame();
        return reply(status_json(), out, size);
    }
    if (action == "tune") {
        if (current_preset() == "none") return fail("tune: the preset is none", out, size);
        const char* names[3] = { "roughness", "specular", "metal" };
        float* fields[3] = { &current.value.roughness, &current.value.specular, &current.value.metal };
        for (int k = 0; k < 3; k++)
            if (const Json* v = params.get(names[k]); v && v->type == Json::Number) {
                if (!(v->number >= 0 && v->number <= 1)) return fail(std::string(names[k]) + " is 0..1", out, size);
                *fields[k] = (float)v->number, current.explicit_fields |= 1u << k;
            }
        if (flag(params, "auto_height", &b)) current.value.auto_height = b, current.explicit_fields |= 8;
        if (const Json* v = params.get("bump"); v && v->type == Json::Number) {
            if (!(v->number >= 0 && v->number <= 4)) return fail("bump is 0..4", out, size);
            current.value.bump = (float)v->number, current.explicit_fields |= 16;
        }
        pc_material_review_frame();
        return reply(status_json(), out, size);
    }
    if (action == "go") {
        bool ok;
        if (const Json* r = params.get("room"); r && r->type == Json::Array && r->items.size() == 2)
            ok = go_room((int)r->items[0].number, (int)r->items[1].number, &error);
        else
            ok = go_next_room(&error);
        if (!ok) return fail("go: " + error, out, size);
        return reply(status_json(), out, size);
    }
    if (action == "decide") {
        if (!decide(str_of(params, "decision"), &error)) return fail("decide: " + error, out, size);
        pc_material_review_frame();
        return reply(status_json(), out, size);
    }
    if (action == "focus") {
        if (!focus(&error)) return fail("focus: " + error, out, size);
        pc_material_review_frame();
        return reply(status_json(), out, size);
    }
    if (action == "settings") { /* {save: false}: applied, not written (a slider being dragged) */
        settings_from(params);
        if ((!flag(params, "save", &b) || b) && !save_state(&error)) return fail(error, out, size);
        pc_material_review_frame();
        return reply(status_json(), out, size);
    }
    return fail("unknown action " + action, out, size);
}
