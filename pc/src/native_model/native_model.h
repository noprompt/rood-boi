/* Native model decoders (pc/docs/plans/2026-11-24-standalone-studio-design.md): a model file read from its bytes into structures that
 * own their memory (native pointers, no guest address, no game state). The game's loaders copy the same bytes into the game's heap and
 * patch them for a texture slot (parse_shp.zig, parse_wep.zig); these decoders keep the file as it is and take the slot as an argument
 * where it matters, so the same decode serves the studio now and the game's loaders later (one format at a time: the seam is the
 * pc_nm_model a loader would be handed instead of walking the buffer).
 *
 * Formats (written from this repository's own loaders: game/battle/shp_file.zig, wep_file.zig, parse_shp.zig, parse_wep.zig, and
 * actor_native.c's record layout):
 *   SHP  +4 u8 bones, u8 vertex groups, u16 triangles; +8 u16 quads, u16 others; +0xC the texture map overlays (0xE8 bytes);
 *        +0xF4 i32 model size N, the model (header offsets at +0x34 groups, +0x38 vertices, +0x3C records; the armatures at +0x40,
 *        16 bytes a bone); the sequence block (4 bytes, i32 length, bytes); the texture block (i32 size: 4 = the model whose texture
 *        this shares, else flags, width/2, height/2, colours, then palettes and the texture).
 *   WEP  +4 i32 bones, i32 quads; +0xC i32 offsets size N, the offsets block (the model's header and records); then the palette
 *        header, the palettes, the texture and the bone info. */
#ifndef ROOD_NATIVE_MODEL_H
#define ROOD_NATIVE_MODEL_H
#include <stddef.h>
#include <stdint.h>
#include "../render.h"

#ifdef __cplusplus
extern "C" {
#endif

enum { PC_NM_FLAT = 0, PC_NM_COLOURED = 1 }; /* the record layouts: pc_model_content_key's kinds 0 and 1 */

typedef struct {
    int length;  /* the bone's length along -x to its children (armature +0) */
    int parent;  /* armature +4 */
    int kind;    /* armature +8: 0 plain, 3..6 spinning, 7..9 faces the camera */
    int lock;    /* armature +12: a bone whose pose a script locks */
    uint8_t raw[16];
} pc_nm_bone;

typedef struct {
    int bones, groups, vertices;
    int counts[3];              /* triangles, quads, others (records of 4/5 or 6/8 words, an other's size in its first word) */
    int kind;                   /* PC_NM_FLAT or PC_NM_COLOURED */
    uint32_t* group_words;      /* per vertex group: end vertex << 16 | bone */
    int16_t (*vertex)[4];       /* x, y, z, pad */
    uint8_t* bone_of;           /* per vertex */
    uint32_t* records;          /* the polygon records as the file has them (a texture slot's rows not added) */
    unsigned record_words;
    pc_nm_bone* bone;
    uint32_t model_head[12];    /* the model block's first 48 bytes: a weapon's material group counts */
    int grouped;                /* drawn by the grouped builders (key kinds 2 and 3): not yet decoded; 0 for every model so far */
    unsigned group_mask;        /* the grouped builders' alternate-palette mask (the object's byte 0x64) */
    uint8_t object_head[8];     /* the file's header bytes 4..11: the actor record's first bytes, what the content key hashes */
    /* the texture: width and height in bytes and rows (4 bits a texel: two a byte; 8 bits: one) */
    int has_texture, shared_model; /* shared_model >= 0: the texture is that model's */
    int texture_width, texture_height, eight_bit;
    int colours;                /* palette entries (16-bit) of the first palette */
    uint16_t* palette;          /* 2 * colours entries: the file's palette words (the second half: the next variant) */
    uint8_t* texels;            /* texture_width * texture_height */
    uint8_t overlays[0xE8];
    uint8_t* sequence;          /* the sequence block (after its 4-byte word and length), kept for the pose decoder */
    unsigned sequence_size;
    int sequence_head;          /* its first byte: how many animations the block holds (the block's header: u8 count, u16 bones, i32 size) */
    int slot_u, slot_v;         /* WEP: the file's own texture box offsets (the loader's texU, texV 0xE0 are added by the host) */
    uint8_t* bone_info;         /* WEP: 8 bytes a bone */
    int wep;                    /* 1: decoded from a WEP */
    int palettes_wep;           /* WEP: palette count after the first (7) and the bytes of each */
    uint8_t* wep_palettes;
    unsigned wep_palette_bytes, wep_first_palette_bytes;
} pc_nm_model;

#include "native_model_formats.h"

/* Decode a SHP / WEP file: 0 on success, else -1 with `err` (the file is not used after the call). */
int pc_nm_shp_decode(const uint8_t* file, size_t size, pc_nm_model* out, char* err, size_t err_size);
int pc_nm_wep_decode(const uint8_t* file, size_t size, pc_nm_model* out, char* err, size_t err_size);
void pc_nm_free(pc_nm_model* m);

/* The model's content key (model_key.h) and the legacy hash actor_native.c names its meshes by. */
uint64_t pc_nm_content_key(const pc_nm_model* m, int u_add, int v_add); /* from the records as the game holds them (a WEP: v_add 224: the key's page reference is taken from them) */
unsigned pc_nm_mesh_hash(const pc_nm_model* m, int u_add, int v_add); /* (the legacy hash names the model with its texture slot's rows in it) */

/* The model's polygons as the renderer takes them (actor_native.c build_mesh's semantics for the flat and coloured layouts). `v_add` is
 * added to every texture v and `u_add` to every u (a texture slot's rows: the loader's fix-up). Returns the count, -1 on bad data;
 * *out is malloc'd. */
int pc_nm_polygons(const pc_nm_model* m, int u_add, int v_add, render_polygon** out);

/* A model's records as a builder sees them: the caller's own memory (the game's model block in its heap, or a decoded pc_nm_model's parts). `kind` is the game's builder kind:
 * 0 flat records, 1 coloured, 2 flat in material groups, 3 coloured in groups (the content key's kinds); `group_counts` (24 counts of 16 bits) and `mask` (the alternate-palette
 * bits) are read for the grouped kinds only. */
typedef struct {
    int kind;
    int counts[3];                  /* triangles, quads, others */
    int vertices;
    const int16_t* vertex;          /* x, y, z, pad for each */
    const uint32_t* records;
    const uint8_t* bone_of;         /* per vertex */
    const uint16_t* group_counts;
    unsigned mask;
} pc_nm_view;
/* What the game's ordering-table sort needs of each polygon (actor_native.c): the polygon's vertices, whether it is a quad, translucent, never culled, and how its ordering-table
 * index and bias follow its depth. */
typedef struct {
    uint16_t vertex[4];
    uint8_t quad, semi, twosided;
    int8_t offset, bias;
} pc_nm_sort;
/* The view's records in words, walked as the packet builders walk them when every face is drawn: 0 when a record's own size disagrees with its kind (or there are none). `limit`
 * bounds the reads (a decoder's buffer; the game's heap block is trusted: pass a large one). */
unsigned pc_nm_record_words(const uint32_t* records, const int counts[3], int coloured, unsigned limit);
/* The view's polygons as the renderer takes them: one reading of the records for the game's actors and weapons and for rood-studio. `u_add` and `v_add` are added to every texture
 * coordinate (the loader's slot fix-up: 0 when the records have it already). `sort` (optional) gets one pc_nm_sort for each polygon, *semi their translucent count. Returns the
 * count (0 for no polygons), -1 when the records or groups are bad; *out and *sort are malloc'd. */
int pc_nm_view_polygons(const pc_nm_view* v, int u_add, int v_add, render_polygon** out, pc_nm_sort** sort, int* semi);

/* A pose: per bone rotation angles (the game's 4096-a-turn units, already halved as the animation keys are used), the root's place and
 * turns. The transforms are model -> world, bone by bone (vs_actors_drawActorModel's chain without the camera and the scales). */
typedef struct {
    int16_t rot[RENDER_MAX_BONES][3];
    uint16_t scale[RENDER_MAX_BONES][3]; /* per-bone scale keys, 64 = 1 (the sequence's, relative to the parent's) */
    float position[3];
    float actor_scale;                  /* the actor's own scale (the game's unit 4/9: 1820 of 4096): every bone's matrix carries it */
    int16_t offset[3];                  /* the root's offset from the actor's place (the sequence's first vector: the hips' height) */
    int rotation_x, facing, rotation_z; /* the actor's own turns on top of bone 0's */
    /* bones the animation's events hold (vs_actors_setActorBonePoseLock): where they were when held, relative to the actor's place, in the world's axes */
    uint8_t locked[RENDER_MAX_BONES];
    float lock_rotation[RENDER_MAX_BONES][3][3], lock_place[RENDER_MAX_BONES][3];
    /* A pose between two of the game's (pc_nm_pose_mix): set, every bone's own turn is the matrix mix_turn (bone 0's with the actor's turns in it) and the scale its matrix carries is mix_scale
     * (the chain's, 64 = 1, mixed), not the angles and keys above, which hold the nearer pose. Zero in every pose the player or the game's state gives. */
    uint8_t mixed;
    float mix_turn[RENDER_MAX_BONES][3][3], mix_scale[RENDER_MAX_BONES][3];
} pc_nm_pose;
/* The studio's pose (rot, scale, actor_scale and the actor's turns) from the game's state: the same values the animation player (pc_nm_anim_pose) leaves, so one pose
 * structure carries both and they can be compared bone for bone. The place and the root's offset stay zero (the game keeps those in the parent matrix). */
void pc_nm_pose_read(const pc_nm_actor_pose* state, pc_nm_pose* pose);
void pc_nm_pose_zero(const pc_nm_model* m, pc_nm_pose* pose); /* every bone's turn zero, the root at the origin facing 0 */
/* The rest pose: animation 0, frame 0 of the SHP's own sequence block (the base sequence; the idle animations are other files). Returns 0, or -1
 * when the block holds no such animation (the pose is then zero). */
int pc_nm_pose_rest(const pc_nm_model* m, pc_nm_pose* pose);
int pc_nm_pose_transforms(const pc_nm_model* m, const pc_nm_pose* pose, render_transform* out);
/* The pose a fraction `t` (0..1) of the way from `a` to `b` (the same model's): each bone's turn is the quaternion slerp of the two (the shortest way round: no shrinking of
 * bone lengths, as a blend of matrices has), scale keys, the root's offset and place linear. 0 gives `a` and 1 `b` exactly (copies). Held bones (events 56 and 57) are
 * mixed when both poses hold them, else the nearer pose's. The actor's turns (rotation_x, facing, rotation_z) are carried in bone 0's turn: set them on both poses first. */
void pc_nm_pose_mix(const pc_nm_model* m, const pc_nm_pose* a, const pc_nm_pose* b, float t, pc_nm_pose* out);

/* ---- sequences: the animation tables and a player (vs_actors_findActorAnimationHeader, vs_actors_initializeActorAnimationPose and
 * vs_actors_decodeAnimationTrack; written from the Zig in game/battle and checked against the game's palettes by rood_studio_smoke.py) ----
 *
 * A table: u32 data offset, u32 index offset, then a record for each distinct animation (nBones * 4 + 10 bytes: u16 frames, u16 ..., u16 events offset,
 * u16 root track, u16 root motion track, one u16 track offset for each bone's turns and, when the record's flag bit 0 is set, for each bone's scale), then the
 * index (one byte for each numbered animation: its record, 0xFF none) and the data. A track is a first vector (three big-endian halves) and packets of
 * frame deltas. A model's animations are numbered 0 (its own table, the SHP's), 1..99 (a ZUD's common table, `commonSeq`) and 100..199 (its battle table,
 * `battleSeq`, the weapon-drawn ones).
 *
 * A table is held as the bytes of the block after its 8-byte header (u8 count, u16 bones, i32 size). */
typedef struct {
    const uint8_t* bytes; /* not owned: the file's or the model's */
    unsigned size;
    int count;            /* the block's animations (its index's length) */
    int bones;            /* the block's bone count, 0: any */
} pc_nm_table;
int pc_nm_table_from_block(const uint8_t* block, size_t size, pc_nm_table* out); /* 0, or -1 */
/* The table and index animation `id` of a model is found in (0: the SHP's own; common and battle may be NULL), -1 when it has none. */
int pc_nm_find_animation(const pc_nm_model* m, const pc_nm_table* common, const pc_nm_table* battle, int id, pc_nm_table* table, int* index);
/* Every animation number the model has, ascending (at most `max`); returns how many. */
int pc_nm_list_animations(const pc_nm_model* m, const pc_nm_table* common, const pc_nm_table* battle, int* ids, int max);

typedef struct pc_nm_anim pc_nm_anim;
pc_nm_anim* pc_nm_anim_open(const pc_nm_model* m, const pc_nm_table* table, int index); /* NULL: not decodable */
int pc_nm_anim_frames(const pc_nm_anim* a);   /* the animation's length in frames */
/* The pose after `time` steps (0 and 1: the first vectors; each step after applies one frame's deltas), as the game's actor shows it. */
void pc_nm_anim_pose(pc_nm_anim* a, int time, pc_nm_pose* pose);
void pc_nm_anim_close(pc_nm_anim* a);
/* An animation's script (vs_actors_runAnimationEvents' stream): each command with the frame it is due on and its argument bytes (the command's length from the game's table less
 * its opcode). Returns how many (at most max); the stream ends at an opcode the table does not know. */
typedef struct {
    int frame, op, length;
    unsigned char arg[6];
} pc_nm_event;
int pc_nm_anim_events(const pc_nm_anim* a, pc_nm_event* out, int max);
/* What the handover between animations (commands 2 and 19 to 24, vs_actors_playActorAnimation) needs of the world: the model's tables, the animation the play starts with (the
 * game's number: 100 and more with the weapon drawn) and the actor's state the game maps the numbers by (the weapon drawn; the stance flags unkA_5, unkA_0 == 3 and unkA_6 of the
 * actor's body, which the decomp leaves unnamed) and command 2's condition (func_8006C84C: the action's hits are done). With none set, an animation that hands over ends the play. */
typedef struct {
    const pc_nm_table *common, *battle;
    int animation;
    int weapon_drawn, stance_a5, stance_a0_3, stance_a6;
    int action_done;
    int event_playback; /* vs_event_playbackPhase == 4 (vs_event_eventPlaybackState: an event is playing, and the game's studio is in that phase): every handover starts the animation, whatever it is */
    int collision_radius; /* the actor's collisionRadius: 0x80 and over doubles the frames of a blend */
    int tickspeed; /* vs_gametime_tickspeed: 4 doubles an update's frames of the animation (framesPerStep): the game at its slow tick; 2 is the normal one */
} pc_nm_world;
void pc_nm_anim_world(pc_nm_anim* a, const pc_nm_world* world);
/* The animation the game plays for `number` in the world (stance and weapon mapping, then the tables, falling back to the model's own animation 0): its number (-1: the model's own
 * animation 0, found), its table and record; 0 when there is none. */
int pc_nm_map_animation(const pc_nm_model* m, const pc_nm_world* world, int number, pc_nm_table* table, int* index);
/* The animation played as the game plays it: `steps` updates of its actor (func_800AFA28, one frame a step) from the animation's start, its script's commands run as
 * vs_actors_runAnimationEvents runs them where they change a pose or its timing: 1 (and 13 where the battle allows it: not run here) restart the animation (the pose and the script
 * from the start: an idle animation loops), 55 waits (the frame counter stands still for its count of steps), 56 and 57 release and hold a bone (vs_actors_setActorBonePoseLock).
 * 61 and 62 (the actor's pace flag unk5B0_3: framesPerStep one or two) change the speed of the updates. A command that starts another animation (2, 19 to 24) plays it on when the
 * animation has a world (pc_nm_anim_world: the mapping by the actor's stance and weapon, the blend of the old pose into the new), else it ends the play: the pose stays as it is.
 * `steps` counts the frames of the animation (a game update takes framesPerStep of them). Everything else (sounds, effects, texture
 * and vertex changes, the actor's motion, the weapon's scale) is the game's business and is skipped. `*frame` (optional) gets the frame counter the pose belongs to. */
void pc_nm_anim_play(pc_nm_anim* a, int steps, pc_nm_pose* pose, int* frame, int* animation);
void pc_nm_anim_holds(pc_nm_anim* a, int on); /* the events' bone holds (on by default) */

/* The first bone whose armature carries `code` (the weapon's 0xF0 and the shield's 0xF1 mark the hand that holds them; func_800A152C field 0), -1 none. */
int pc_nm_find_bone(const pc_nm_model* m, int code);
/* The weapon pose of a decoded weapon (scale 64: whole): what the game's record holds for it once loaded. Returns the bone count, -1 when the model is no weapon. */
int pc_nm_weapon_pose_of(const pc_nm_model* weapon, pc_nm_weapon_pose* pose);
/* A weapon's bones (vs_actors_buildWeaponBoneChain): bone 0 is `hand`, the holder's bone matrix (its columns scaled by pose->scale / 64); the others hang from it by the
 * pose's parents, lengths and turns. Returns the bone count, -1 when the pose is not a chain. */
int pc_nm_weapon_transforms(const pc_nm_weapon_pose* pose, const render_transform* hand, render_transform* out);

/* Rotation from the game's angles (Rz * Ry * Rx, 4096 a turn). */
void pc_nm_euler(int ax, int ay, int az, float r[3][3]);

#ifdef __cplusplus
}
#endif
#endif
