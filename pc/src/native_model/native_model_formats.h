/* The file formats' layouts as plain C (no includes: the game's own headers take it too): where the parts of a model file are, from its bytes alone, and
 * the fix-up the loaders make of its polygon records. One reading of each format, shared by the game's loaders (game/battle) and rood-studio's decoders
 * (native_model.h); pc/docs/plans/2026-11-24-standalone-studio-design.md, "the seam for the game's loaders". The files are trusted to be whole here;
 * the decoders check them. */
#ifndef ROOD_NATIVE_MODEL_FORMATS_H
#define ROOD_NATIVE_MODEL_FORMATS_H

/* A WEP file's layout: where its parts are, from its bytes alone (no size, no copy: what a loader walking the file's buffer needs). The file is
 * trusted to be whole; pc_nm_wep_decode checks it. */
typedef struct {
    int n_bones, n_quads;
    unsigned offsets_size, tex_width;
    int palette_size;                   /* the file's byte: 96 is a double palette */
    unsigned first_palette_bytes, palette_bytes;
    const unsigned char *offsets, *palette_first, *palettes, *texture, *bone_info;
} pc_nm_wep_parts;
void pc_nm_wep_layout(const unsigned char* file, pc_nm_wep_parts* out);
/* A model's polygon records with a texture slot's columns and rows added to every texture coordinate, in place (the loaders' fix-up); `kind` PC_NM_FLAT or PC_NM_COLOURED. */
void pc_nm_fix_records(void* records, int triangles, int quads, int others, int kind, int u_add, int v_add);


/* An SHP file (an actor's shape): the counts, the texture map overlays, the model block, the sequence block's start and the texture block, from its bytes alone. A texture block of
 * size 4 names the model whose texture this one shares (shared_model_id); else flags (bit 0: the wide palette, the high nibble: the coloured records), the texture's width and
 * height in bytes and rows, the palette's colour count, the palettes and the texels. */
typedef struct {
    int n_bones, n_quads;
    const unsigned char *overlays, *model;
    int model_size;
    const unsigned char* seq;
    int texture_block_size, shared_model_id;
    unsigned char flags;
    int width, height;
    unsigned char clut_count;
    const unsigned char *cluts, *texture;
} pc_nm_shp_parts;
void pc_nm_shp_layout(const unsigned char* file, pc_nm_shp_parts* out);

/* A ZUD file (an enemy's package, loaded by the zone's enemy table and by the ENEMY menu): a 0x30-byte header, then the parts it names by byte offset from the file's start.
 *   +0x00 u8 characterId, weapon, weaponCategory, weaponMaterial, shield, shieldMaterial, defaultMaterial, (pad)
 *   +0x08 u32 offset, i32 size of each part, in this order: shp (the model), weaponWep, shieldWep, commonSeq, battleSeq
 * The parts stay raw in the file's buffer, where the object loader (vs_battle_populateDataSlot) reads them; each part's pointer is the file's address plus its offset. */
typedef struct {
    void* data;
    int size;
} pc_nm_zud_part;
typedef struct {
    unsigned char characterId, weapon, weaponCategory, weaponMaterial, shield, shieldMaterial, defaultMaterial;
    pc_nm_zud_part shp, weaponWep, shieldWep, commonSeq, battleSeq;
} pc_nm_zud;
void pc_nm_zud_decode(pc_nm_zud* out, const void* file);

/* A sequence block (the SHP's, a ZUD's common and battle parts, a weapon's and the effects'): u8 head (the animation count; the weapon kind: its animation count), u16 bones (0: any),
 * i32 size, then the data. A table in the data: u32 data offset, u32 index offset, the animation records (nBones * 4 + 10 bytes each) from +8, the index (a byte for each numbered
 * animation: its record, 0xFF none) and the animation streams. A shared set: i32 count N, N u16 animation ids and N u16 keys (4 bytes each), N u32 stream offsets counted from the end of the tables. */
typedef struct {
    unsigned char head;
    unsigned short bones;
    int size;
    const unsigned char* data;
} pc_nm_seq_block;
void pc_nm_seq_block_at(const unsigned char* at, pc_nm_seq_block* out);
typedef struct {
    int count;
    const unsigned char* base;
} pc_nm_seq_shared;
void pc_nm_seq_shared_at(const unsigned char* at, pc_nm_seq_shared* out);
unsigned short pc_nm_seq_shared_id(const pc_nm_seq_shared* set, int i);
unsigned short pc_nm_seq_shared_key(const pc_nm_seq_shared* set, int i);
unsigned pc_nm_seq_shared_offset(const pc_nm_seq_shared* set, int i);
const unsigned char* pc_nm_seq_shared_streams(const pc_nm_seq_shared* set); /* where the offsets count from */
/* A table's animation `idx`: its record's byte offset in the table (from the table's start), -1 when the index holds 0xFF; *record gets the index byte. An `idx` below zero reads
 * before the index, as the game's does. */
int pc_nm_table_record(const unsigned char* table, int bones, int idx, int* record);

/* One animation track (vs_actors_decodeAnimationTrack's stream): the first vector's value, then packets of frame deltas. The track's state is this struct:
 * the position in the stream (`pos`), the frame the current delta lasts to (`next`), the delta and the value. `stream` is the track's own bytes (the table's data
 * from the track's offset); `length` bounds the reads. pc_nm_track_step applies one frame: it reads the packets the frame needs, then adds the delta to the value
 * (`rotation`: the turns keep 13 bits). It sets `ended` (nothing applied) when the stream ends in a zero byte. */
typedef struct {
    const unsigned char* stream;
    unsigned length;
    unsigned pos;
    int next;
    short delta[3], val[3];
    int live;  /* it has packets to read */
    int ended;
} pc_nm_track;
void pc_nm_track_step(pc_nm_track* t, int frame, int rotation);
/* The table's data (the animation streams): the table's first word is its offset. */
const unsigned char* pc_nm_table_data(const unsigned char* table);
/* A first vector: three big-endian halves, each doubled (the turns and the root). */
void pc_nm_initial_vector(const unsigned char* at, short out[3]);

/* Where a model's texture and palette live in the emulated VRAM, written once (the loaders' slot tables, the slot records the renderer's page words come from, and the studio's
 * uploads all read it). A texture slot is a place for a model's texels: `page_x`, `page_y` the texture page's corner (what GetTPage takes), `x`, `y` where the texels go
 * (LoadImage's rectangle, and the slot's origin for the texture animations), `u_add`, `v_add` what the loader adds to every texture coordinate of the model's records.
 * The actors have 24 slots (shapes take one to eight of them, in 4-bit or 8-bit pages: 64 x 64 texels each), the weapons 20 (8-bit, 64 x 32 texels, two to a page). 0 when `slot`
 * is outside the table. */
typedef struct {
    int page_x, page_y, x, y, u_add, v_add;
} pc_nm_texture_slot;
int pc_nm_actor_texture_slot(int slot, pc_nm_texture_slot* out);
int pc_nm_weapon_texture_slot(int slot, pc_nm_texture_slot* out);
/* A palette's row: an actor's two (the colours the model's records name, the second the copy the renderer's alternate palette reads) are rows 228 + index and 246 + index of
 * the column 768 (`which` 0, 1); a weapon's `slot` (the CLUT slot: the palette group, twice the actor's slot plus 16 and the holder's bone code) is a pair at the column
 * 928 + 48 * (slot & 1), the row 228 + slot / 2. */
int pc_nm_actor_palette_row(int index, int which);

/* The slots' reference counts (the game's slot records keep them, where its save states do: `refs` the first record's count byte, `stride` the records' size). The loaders
 * give a model its slots from them: an actor takes `n` (1 to 8) slots of [lo, hi) the way the shape loader always searched (one or two at the first free step of n, three or
 * four the first free run not crossing a group of four, eight only when every slot of the range is free, any other count the first slot): the slot, or -1 when none fits.
 * A weapon takes one slot, or a pair of the same page (`wide`): the first free one, both marked taken; -1 when none is. */
int pc_nm_actor_slots_find(const unsigned char* refs, int stride, int n, int lo, int hi);
int pc_nm_weapon_slots_take(unsigned char* refs, int stride, int wide);

/* The loaders hold their file's buffer and not its length: a file's length from its own header (where its last part ends, as the decoders check it), for the decoder. */
unsigned pc_nm_wep_size(const unsigned char* file);
unsigned pc_nm_shp_size(const unsigned char* file);
/* The loaders' texture step through the decoded model: decode the file, put its texels into slot `slot` of the texture's kind (a texture object and its upload) and copy its
 * palettes out where the loader keeps them: a weapon's first palette to `first` and the seven others to `others`, a palette every `stride` bytes; a shape's palettes (its colour count of 4-byte entries) to
 * `cluts`. 0, or -1 when the file does not decode (nothing is written then). */
int pc_nm_wep_load_texture(const unsigned char* file, int slot, void* first, void* others, int stride);
int pc_nm_shp_load_texture(const unsigned char* file, int slot, void* cluts);

/* A model's texture as the loaders and rood-studio hold it: the place it occupies (a slot of `kind` PC_NM_TEXTURE_ACTOR or PC_NM_TEXTURE_WEAPON) and the size of its texels,
 * made once from the slot and the dimensions; its upload is the one way the texels reach the emulated VRAM (the renderer reads them by page, CLUT and box from there).
 * `width` is in texels as the files give it (4-bit: two to a byte, 8-bit: one), `words` in the 16-bit words LoadImage counts, `rows` the height. */
enum { PC_NM_TEXTURE_ACTOR = 0, PC_NM_TEXTURE_WEAPON = 1 };
typedef struct {
    int kind, slot;
    pc_nm_texture_slot place;
    int words, rows;
} pc_nm_texture;
/* 0 when `slot` is outside the kind's table. */
int pc_nm_texture_at(pc_nm_texture* t, int kind, int slot, int width, int rows);
/* The texels (words * rows 16-bit words, any alignment) into the texture's place. */
void pc_nm_texture_upload(const pc_nm_texture* t, const void* texels);
/* A palette (`words` colours of 16 bits) into the row at (x, y). */
void pc_nm_palette_upload(int x, int y, int words, const void* colours);
void pc_nm_weapon_palette_at(int slot, int* x, int* y);
/* The same places as vs_main_loadClut names them (its slot: the row less 224; its colour offset: the column less 768). */
void pc_nm_actor_palette_clut(int index, int which, int* slot, int* offset);
void pc_nm_weapon_palette_clut(int slot, int* clut_slot, int* offset);

#endif
