#ifndef ROOD_RT_CACHE_GLSL
#define ROOD_RT_CACHE_GLSL
// The radiance cache (pc/docs/Vulkan_Renderer.md, "Radiance cache"): a hash
// table in a storage buffer of the light that leaves the room's surfaces, keyed
// by the surface point's cell and the face it looks along. A cell's size grows
// with its distance from the eye (detail where you look). rt_cache_update.comp
// traces a few short paths from a sparse set of pixels and deposits what they
// find into the cells they pass through; rt_cache_resolve.comp folds each
// frame's deposits into the cells' running means and drops the cells nobody
// has used for a while; rt_trace.comp reads a cell instead of tracing the
// bounces past its first hit.
// Two kinds of cell share the table. A radiance cell (kind 0) holds the light
// that leaves a surface point, as the paths' hits find it (the light that
// goes round: what a path that reaches the cell can stop with). An
// irradiance cell (kind 1) holds the light that arrives at a surface point
// the camera sees, from the paths that start there: what the pixels' GI is,
// read without a ray.
// A slot is CACHE_STRIDE words: 0 key check (0: empty); 1..3 this frame's
// deposited light (fixed point), 4 its sample count; 5..7 the resolved light
// (float bits), 8 the samples it is made of (capped), 9 the frame it was last
// used in; 10 this frame's deposited distance of the paths' first hits
// (fixed point), 11 its resolved mean (float bits; NRD's hit distance).
layout(std430, binding = 14) buffer RadianceCache { uint cache_[]; };
const uint CACHE_STRIDE = 12u;
const float CACHE_FIXED = 1024.0; // deposited light, as fixed point (atomic adds)
const float CACHE_DISTANCE_FIXED = 16.0;
const float CACHE_SAMPLE_MAX = 32.0; // one sample's light is capped here (a lone bright sample cannot flood a cell)
#define cache_on (u.i4.x != 0)
#define cache_mask uint(u.i4.y)
#define cache_tile u.i4.z
#define cache_bounces u.i4.w
#define cache_settle uint(u.i5.x)
#define cache_min uint(u.i5.y)
#define cache_bilinear (u.i5.z != 0)
#define cache_cell u.f3.x
#define cache_lod u.f3.y
#define cache_jitter u.f3.z
#define cache_refresh u.f3.w
uint hash_u(uint x) {
    x ^= x >> 16; x *= 0x7feb352du; x ^= x >> 15; x *= 0x846ca68bu; x ^= x >> 16;
    return x;
}
// The face a normal looks along: 0..5 (+x, -x, +y, -y, +z, -z).
uint cache_face(vec3 n) {
    vec3 a = abs(n);
    uint axis = a.x >= a.y && a.x >= a.z ? 0u : (a.y >= a.z ? 1u : 2u);
    return axis * 2u + (n[axis] < 0.0 ? 1u : 0u);
}
// A cell of the table: the slot it starts at and the check word that tells it.
uvec2 cache_key(vec3 p, vec3 n, uint kind) {
    float level = max(floor(log2(max(distance(p, eye) / cache_lod, 1.0))), 0.0);
    float cell = cache_cell * exp2(level);
    ivec3 c = ivec3(floor(p / cell));
    uint h = hash_u(uint(level) * 16u + kind * 8u + cache_face(n));
    h = hash_u(h + uint(c.x));
    h = hash_u(h + uint(c.y));
    h = hash_u(h + uint(c.z));
    return uvec2(h & cache_mask, hash_u(h ^ 0x9e3779b9u) | 1u);
}
// The cell's slot (-1: not there, or the table is full around it); `insert` claims an empty one.
int cache_find(uvec2 key, bool insert) {
    for (uint i = 0u; i < 8u; i++) {
        uint s = (key.x + i) & cache_mask, k = cache_[s * CACHE_STRIDE];
        if (k == key.y) return int(s);
        if (k == 0u) {
            if (!insert) return -1;
            uint old = atomicCompSwap(cache_[s * CACHE_STRIDE], 0u, key.y);
            if (old == 0u || old == key.y) return int(s);
        }
    }
    return -1;
}
// The light the cell at p (a surface point facing n) sends back: rgb, and in w how many samples it is made of (0: none).
// `shift` moves the lookup along the surface (the stochastic filter between cells).
vec4 cache_read(vec3 p, vec3 n, vec3 shift, uint kind, out float hit_distance) {
    hit_distance = 0.0;
    int s = cache_find(cache_key(p + shift, n, kind), false);
    if (s < 0) return vec4(0.0);
    uint b = uint(s) * CACHE_STRIDE;
    if (cache_[b + 9u] != frame) atomicMax(cache_[b + 9u], frame);
    hit_distance = uintBitsToFloat(cache_[b + 11u]);
    return vec4(uintBitsToFloat(cache_[b + 5u]), uintBitsToFloat(cache_[b + 6u]), uintBitsToFloat(cache_[b + 7u]), float(cache_[b + 8u]));
}
// One more sample of the light leaving p (facing n).
void cache_deposit(vec3 p, vec3 n, vec3 light, uint kind, float hit_distance) {
    if (any(isnan(light)) || any(isinf(light))) return;
    int s = cache_find(cache_key(p, n, kind), true);
    if (s < 0) return;
    uint b = uint(s) * CACHE_STRIDE;
    uvec3 f = uvec3(clamp(light, 0.0, CACHE_SAMPLE_MAX) * CACHE_FIXED + 0.5);
    atomicAdd(cache_[b + 1u], f.x); atomicAdd(cache_[b + 2u], f.y); atomicAdd(cache_[b + 3u], f.z);
    atomicAdd(cache_[b + 4u], 1u);
    if (hit_distance > 0.0) atomicAdd(cache_[b + 10u], uint(min(hit_distance, 4096.0) * CACHE_DISTANCE_FIXED + 0.5));
    atomicMax(cache_[b + 9u], frame);
}
#endif
