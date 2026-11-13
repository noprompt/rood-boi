/* The present frame header and its scramble canary (present_header.h). Host state. */
#ifndef _WIN32
#include <execinfo.h> /* (the canary trace's backtrace; none on Windows) */
#endif
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "present_header.h"
#include "antialias.h"
#include "atmosphere.h"
#include "emissive.h"
#include "lighting_quality.h"
#include "post.h"
#include "light_list.h"
#include "ui/menu_light.h"

extern void pc_scene_bounds(float lo[3], float hi[3]);
extern int pc_scene_camera_get(float (*)[3], float*, float*, float*, float*);
extern int pc_scene_camera_inverse(float inverse[3][3]);
extern int pc_scene_projection(float*, float*, float*);
extern int pc_scene_game_camera(float rotation[3][3], float translation[3], float* h, float* ofx, float* ofy);
extern int pc_scene_invert_camera(const float r[3][3], float inverse[3][3]);
extern int pc_hw_view_camera(float r[3][3], float t[3], float* h, float* ofx, float* ofy) __attribute__((weak));
extern int pc_hw_replay_camera(float r[3][3], float t[3]) __attribute__((weak));
extern int pc_hw_replay_projection(float* h, float* ofx, float* ofy) __attribute__((weak));
extern void pc_baked_shadow_params(float out[5]);
extern int pc_ui_menu_active(void) __attribute__((weak));
extern int pc_ui_menu_backdrop(float rgba[4]) __attribute__((weak));
extern int pc_ui_menu_model_light(pc_menu_light* out) __attribute__((weak));
extern int pc_photo_capture_wanted(void) __attribute__((weak));
extern int pc_emissive_active(void);
extern void pc_lighting_sync(void);
extern int pc_lighting_ao_traced(void);
extern float pc_lighting_traced_haze_density(void);
extern int pc_scene_serial(void), pc_scene_uv_serial(void);
extern const int* pc_scene_animated(int* count);
extern int pc_lighting_ssao(int traced_this_frame);
extern float pc_lighting_low_haze_density(int traced_haze);
extern float pc_lighting_baked_scale(float room_baked, int light_count);

extern int pc_baked_shadows_active, pc_display_rgb24, pc_gi_debug, pc_gi_enabled, pc_gl_aa, pc_gl_aspect, pc_gl_filter,
    pc_gl_show_depth, pc_gl_view_mode, pc_gte_widescreen, pc_present_brightness, pc_rt_shadows;
extern float pc_fog_anisotropy, pc_fog_density, pc_gi_strength, pc_light_size, pc_lights_baked, pc_normal_smoothing,
    pc_shadow_softness;
extern int pc_gl_inset[4];
extern int pc_baked_shadows, pc_fog_steps, pc_gi_bounces, pc_gi_denoise, pc_gi_rays, pc_gi_trace_debug, pc_glow_shadows, pc_nrd_glow, pc_nrd_max_frames, pc_probe_budget, pc_probe_rays, pc_probe_show, pc_shadow_samples, pc_fog_volume_render, pc_fog_volume_shadows, pc_fog_volume_steps, pc_haze_cell, pc_reflection_bounces, pc_gi_method, pc_haze_quality, pc_lights_enabled, pc_particles_untraced;
extern float pc_baked_ambient, pc_contact_radius, pc_emitter_light, pc_fog_glow, pc_gi_baked_bounce, pc_gi_resolution, pc_haze_history, pc_probe_hysteresis, pc_probe_normal_bias, pc_probe_spacing, pc_probe_view_bias, pc_shadow_history, pc_shadow_motion_history, pc_fog_volume_history, pc_fog_volume_resolution;

pc_present_header pc_present_header_now __attribute__((section(".data.rood_host")));
int pc_present_inside, pc_present_guard_on, pc_present_paused;
static struct {
    const char* what;
    unsigned long long count;
} violations[64];
static int violation_count, abort_on_violation;
static void report_violations(void)
{
    for (int i = 0; i < violation_count; i++)
        fprintf(stderr, "[present-canary] live read of %s from the present: %llu calls\n", violations[i].what, violations[i].count);
}
void pc_present_violation(const char* what)
{
    for (int i = 0; i < violation_count; i++)
        if (!strcmp(violations[i].what, what)) {
            ++violations[i].count;
            return;
        }
    if (abort_on_violation) {
        fprintf(stderr, "[present-canary] live read of %s from the present\n", what);
        abort();
    }
    if (violation_count < 64) {
        if (!violation_count)
            atexit(report_violations);
        violations[violation_count].what = what, violations[violation_count++].count = 1;
        if (getenv("ROOD_PRESENT_CANARY_TRACE")) { /* where it was called from (first call of each) */
            fprintf(stderr, "[present-canary] %s called from:\n", what);
#ifndef _WIN32
            void* frames[10];
            backtrace_symbols_fd(frames, backtrace(frames, 10), 2);
#endif
        }
    }
}
static int canary = -1, canary_level;
static struct {
    const char* name;
    void* live;
    unsigned char saved[16];
    int size;
} entries[128];
static int entry_count, paused;

/* Read inside the present by the renderer's own record-time and replay code (gpu_hw.c, lights.cpp's projection), which takes the widescreen
 * flag live: it belongs to the frame header of the adopted frame (T4), not the present's. Level 1 of the canary leaves it alone; level 2
 * (ROOD_PRESENT_CANARY=2) poisons it too and differs until the recordings carry it. */
static const char* const shared_with_scene_code[] = { "gte_widescreen" };
/* ROOD_PRESENT_CANARY_SKIP=name,name: variables left alone (finding which live read a run still has). */
static void add(const char* name, void* live, int size)
{
    const char* skip = getenv("ROOD_PRESENT_CANARY_SKIP");
    size_t n = strlen(name);
    if (canary_level < 2)
        for (size_t k = 0; k < sizeof shared_with_scene_code / sizeof *shared_with_scene_code; k++)
            if (!strcmp(name, shared_with_scene_code[k]))
                return;
    for (const char* p = skip; p && *p;) {
        const char* end = strchr(p, ',');
        size_t len = end ? (size_t)(end - p) : strlen(p);
        if (len == n && !strncmp(p, name, n))
            return;
        p = end ? end + 1 : p + len;
    }
    entries[entry_count].name = name, entries[entry_count].live = live, entries[entry_count].size = size;
    ++entry_count;
}
static void catalogue(void)
{
    if (entry_count)
        return;
#define PC_PH_ADD(f, live) add(#f, &live, sizeof live);
    PC_PH_INTS(PC_PH_ADD)
    PC_PH_FLOATS(PC_PH_ADD)
#undef PC_PH_ADD
    add("gl_inset", pc_gl_inset, sizeof pc_gl_inset);
}
void pc_present_header_fill(void)
{
    pc_present_header* h = &pc_present_header_now;
    pc_lighting_sync(); /* lighting quality: first-run preset, Custom on changes (the game thread's: it writes the settings) */
#define PC_PH_COPY(f, live) h->f = live;
    PC_PH_INTS(PC_PH_COPY)
    PC_PH_FLOATS(PC_PH_COPY)
#undef PC_PH_COPY
    memcpy(h->gl_inset, pc_gl_inset, sizeof h->gl_inset);
    /* the scene */
    h->game_camera_ok = pc_scene_game_camera(h->game_r, h->game_t, &h->game_h, &h->game_ofx, &h->game_ofy);
    h->projection_ok = h->game_camera_ok && h->game_h > 0;
    pc_scene_bounds(h->room_lo, h->room_hi);
    /* the lights */
    h->light_count = h->projection_ok ? pc_lights_list(h->lights, PC_LIGHTS_MAX) : 0;
    pc_baked_shadow_params(h->baked_shadow);
    /* the menu */
    h->menu_active = pc_ui_menu_active && pc_ui_menu_active();
    h->menu_backdrop_ok = pc_ui_menu_backdrop && pc_ui_menu_backdrop(h->menu_backdrop);
    h->menu_light_ok = pc_ui_menu_model_light && pc_ui_menu_model_light(&h->menu_light);
    /* post, photo, emissive, lighting quality */
    pc_post_frame_get(&h->post);
    h->photo_wanted = pc_photo_capture_wanted && pc_photo_capture_wanted();
    h->emissive_active = pc_emissive_active();
    h->ao_traced = pc_lighting_ao_traced();
    h->ssao[0] = pc_lighting_ssao(0), h->ssao[1] = pc_lighting_ssao(1);
    h->low_haze = pc_lighting_low_haze_density(0);
    h->baked_scale = pc_lighting_baked_scale(h->lights_baked, h->light_count);
    h->traced_haze = pc_lighting_traced_haze_density();
    h->scene_serial = pc_scene_serial(), h->scene_uv_serial = pc_scene_uv_serial();
    {
        int count = 0;
        const int* animated = pc_scene_animated(&count);
        h->animated_overflow = count > 4096;
        h->animated_count = count > 4096 ? 4096 : count;
        if (animated)
            memcpy(h->animated, animated, (size_t)h->animated_count * sizeof *h->animated);
    }
    h->light_count_all = pc_lights_list(h->lights_all, PC_LIGHTS_MAX);
}
void pc_ph_scene_bounds(float lo[3], float hi[3])
{
    if (!pc_present_inside)
        return pc_scene_bounds(lo, hi);
    memcpy(lo, pc_present_header_now.room_lo, sizeof pc_present_header_now.room_lo);
    memcpy(hi, pc_present_header_now.room_hi, sizeof pc_present_header_now.room_hi);
}
int pc_ph_scene_camera_get(float rotation[3][3], float translation[3], float* h, float* ofx, float* ofy)
{
    if (!pc_present_inside)
        return pc_scene_camera_get(rotation, translation, h, ofx, ofy);
    const pc_present_header* p = &pc_present_header_now;
    if (!p->game_camera_ok)
        return 0;
    memcpy(rotation, p->game_r, sizeof p->game_r), memcpy(translation, p->game_t, sizeof p->game_t);
    *h = p->game_h, *ofx = p->game_ofx, *ofy = p->game_ofy;
    /* the picture's camera: the renderer's own state, applied now (scene_capture.c pc_scene_camera_get does the same to the live camera) */
    if (pc_hw_view_camera && pc_hw_view_camera(rotation, translation, h, ofx, ofy))
        return 1;
    if (pc_hw_replay_camera)
        pc_hw_replay_camera(rotation, translation);
    if (pc_hw_replay_projection)
        pc_hw_replay_projection(h, ofx, ofy);
    return 1;
}
int pc_ph_scene_camera_inverse(float inverse[3][3])
{
    if (!pc_present_inside)
        return pc_scene_camera_inverse(inverse);
    float r[3][3], t[3], h, ofx, ofy;
    return pc_ph_scene_camera_get(r, t, &h, &ofx, &ofy) && pc_scene_invert_camera(r, inverse);
}
int pc_ph_scene_projection(float* h, float* ofx, float* ofy)
{
    if (!pc_present_inside)
        return pc_scene_projection(h, ofx, ofy);
    float r[3][3], t[3];
    if (!pc_present_header_now.projection_ok)
        return 0;
    return pc_ph_scene_camera_get(r, t, h, ofx, ofy);
}
int pc_ph_scene_serial(void) { return pc_present_inside ? pc_present_header_now.scene_serial : pc_scene_serial(); }
int pc_ph_scene_uv_serial(void) { return pc_present_inside ? pc_present_header_now.scene_uv_serial : pc_scene_uv_serial(); }
const int* pc_ph_scene_animated(int* count)
{
    if (!pc_present_inside || pc_present_header_now.animated_overflow)
        return pc_scene_animated(count);
    *count = pc_present_header_now.animated_count;
    return pc_present_header_now.animated;
}
int pc_ph_lights_list(pc_light_gpu* out, int max)
{
    if (!pc_present_inside)
        return pc_lights_list(out, max);
    int n = pc_present_header_now.light_count_all < max ? pc_present_header_now.light_count_all : max;
    memcpy(out, pc_present_header_now.lights_all, (size_t)n * sizeof *out);
    return n;
}
int pc_ph_lighting_ao_traced(void) { return pc_present_inside ? pc_present_header_now.ao_traced : pc_lighting_ao_traced(); }
float pc_ph_lighting_traced_haze_density(void) { return pc_present_inside ? pc_present_header_now.traced_haze : pc_lighting_traced_haze_density(); }
static void poison(int on)
{
    for (int i = 0; i < entry_count; i++) {
        if (on) {
            memcpy(entries[i].saved, entries[i].live, (size_t)entries[i].size);
            memset(entries[i].live, 0xA5, (size_t)entries[i].size); /* ints 0xA5A5A5A5, floats a large negative */
        } else {
            /* Restore what the poison still covers; a variable the renderer side wrote meanwhile (GI turning itself off when it cannot
             * start, the baked shadow flag the game's drop shadow reads) keeps its value: that write is the renderer's reply. */
            unsigned char* live = entries[i].live;
            int poisoned = 1;
            for (int k = 0; k < entries[i].size; k++)
                poisoned &= live[k] == 0xA5;
            if (poisoned)
                memcpy(entries[i].live, entries[i].saved, (size_t)entries[i].size);
        }
    }
}
void pc_present_enter(void)
{
    if (canary < 0) {
        const char* v = getenv("ROOD_PRESENT_CANARY");
        canary = v && (*v == '1' || *v == '2');
        canary_level = canary ? *v - '0' : 0;
        pc_present_guard_on = getenv("ROOD_PRESENT_CANARY_CALLS") != NULL;
        abort_on_violation = getenv("ROOD_PRESENT_CANARY_ABORT") != NULL;
        catalogue();
    }
    pc_present_inside = 1;
    if (canary) {
        poison(1);
        paused = 0;
    }
}
void pc_present_leave(void)
{
    if (canary) {
        if (!paused)
            poison(0);
        paused = 0;
    }
    pc_present_inside = pc_present_paused = 0;
    static unsigned leaves;
    if (pc_present_guard_on && ++leaves % 600 == 0)
        report_violations(); /* (the game may not exit through atexit) */
}
void pc_present_canary_pause(int on)
{
    pc_present_paused = on;
    if (!canary || on == paused)
        return;
    if (on)
        poison(0); /* the live values back */
    else
        poison(1); /* (taking them again: the panel's edits are the new live values) */
    paused = on;
}
