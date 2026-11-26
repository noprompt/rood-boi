//! Parses a weapon model file (WEP) into its model slot, in two passes (pc/src/game/BATTLE/BATTLE.PRG/30DB0.c).
const psx = @import("common").psx;
const v = @import("views_30DB0");
const c = @import("c_30DB0");
const wep_file = @import("wep_file.zig");

/// The C calls memcpy and memset without a prototype: an int size goes as its 32 bits, zero-extended.
const Memcpy = *const fn (?*anyopaque, ?*const anyopaque, usize) callconv(.c) ?*anyopaque;
const Memset = *const fn (?*anyopaque, c_int, usize) callconv(.c) ?*anyopaque;

inline fn intBits(size: c_int) usize {
    return @as(u32, @bitCast(size));
}

/// orig: _parseWep (pc/src/game/BATTLE/BATTLE.PRG/30DB0.c)
/// First pass (D_800E8F29 0): shares an identical model already loaded, or reads the header, the offsets block,
/// a free texture slot, the palettes and the texture (returns -1, D_800E8F29 1). Second pass (1): shifts the
/// polygons' UVs into the texture slot and copies the bone info. Returns 0 when done, -2/-3 on failure.
pub fn parseWep(object: *v.vs_battle_objectData) callconv(.c) c_int {
    const memcpy = @extern(Memcpy, .{ .name = "memcpy" });
    const memset = @extern(Memset, .{ .name = "memset" });
    const models = v.g.vs_battle_wepModels();
    var model = psx.at(models, object.index).*;
    var data: usize = object.dataAddr;

    const Next = enum { parse, copy_slot, fix_prims };
    var next: Next = .parse;
    const pass = v.g.D_800E8F29();
    if (pass.* == 0) {
        if (model == null) {
            psx.at(models, object.index).* = @ptrCast(@alignCast(psx.get(object.destination)));
            model = psx.at(models, object.index).*;
            if (model == null) return -2;
            _ = memset(model, 0, @sizeOf(v.vs_battle_wepModels_t));
            model.?.texSlot = 0xFF;
        }
        if (model.?.nBones != 0) return -3;

        if (data < 20) {
            next = .copy_slot;
        } else {
            var found = false;
            var j: c_int = 0;
            while (j < 20) : (j += 1) { // j < 20: the slot count
                if (j != object.index) {
                    if (models[@intCast(j)]) |other| {
                        if ((psx.getBits(other, "actorId") != 0 or object.index < 4) and
                            @as(c_int, other.modelId) == object.modelId)
                        {
                            object.dataAddr = @intCast(j);
                            found = true;
                            break;
                        }
                    }
                }
            }
            if (found) {
                data = object.dataAddr;
                next = .copy_slot;
            } else {
                model.?.modelId = psx.conv(u8, object.modelId);
            }
        }
    } else if (pass.* == 1) {
        data = @intFromPtr((wep_file.current() orelse return -2).bone_info);
        next = .fix_prims;
    }

    switch (next) {
        .copy_slot => {
            const m = model.?;
            const slot: usize = data;
            c.vs_main_memcpy(m, models[slot], @sizeOf(v.vs_battle_wepModels_t));
            if (m.texSlot != 0xFF) {
                const textures = v.g.vs_battle_wepTextures();
                psx.at(textures, m.texSlot).refCount +%= 1;
                if (psx.getBits(m, "isWideTexture") != 0) {
                    psx.at(textures, @as(c_int, m.texSlot) + 1).refCount +%= 1;
                }
            }
            if (object.index < 4) {
                data = @intFromPtr(psx.get(m.offsets));
                var buf: ?*v._wepModelOffsets = undefined;
                if (object.index < 2) {
                    buf = v.g.vs_battle_commonWepBuffs()[@intCast(object.index)];
                    psx.put(&m.offsets, buf);
                } else {
                    buf = @ptrCast(@alignCast(c.vs_main_allocHeap(@sizeOf(v._wepModelOffsets))));
                    psx.put(&m.offsets, buf);
                }
                c.vs_main_memcpy(buf, @ptrFromInt(data), @sizeOf(v._wepModelOffsets));
            }
            m.clutSlotOffset = psx.conv(u8, @as(c_int, object.unk11) +% (@as(c_int, object.actorId) << 1) +% 16);
            c._loadMaterialPalette(object.index, object.material);
            m.scale = 64;
            psx.setBits(m, "unk8_4", 0);
            psx.setBits(m, "unk8_6", 0);
            m.scaleSteps = 0;
            psx.setBits(m, "actorId", psx.conv(u4, object.actorId));
            m.unkC = object.unk11;
            m.unkD = psx.conv(u8, c.func_800A152C(object.actorId, object.unk11, 0));
            pass.* = 0;
            return 0;
        },
        .fix_prims => {
            const m = model.?;
            const offsets = psx.get(m.offsets).?;
            const records: [*]u8 = @ptrFromInt(@intFromPtr(offsets) +% @as(u32, @bitCast(offsets.polygonsOffset)));
            var place: c.pc_nm_texture_slot = undefined;
            if (c.pc_nm_weapon_texture_slot(m.texSlot, &place) == 0) return -2;
            // the texture slot's column and row added to every texture coordinate: native_model's, the flat records' layout
            c.pc_nm_fix_records(records, m.nTriangles, m.nQuads, m.nOther, 0, place.u_add, place.v_add);
            _ = memcpy(&m.unkBoneInfo, @ptrFromInt(data), intBits(@as(c_int, m.nBones) * 8));
            wep_file.release();
            c._loadMaterialPalette(object.index, object.material);
            m.scale = 64;
            psx.setBits(m, "unk8_4", 0);
            psx.setBits(m, "unk8_6", 0);
            m.scaleSteps = 0;
            psx.setBits(m, "actorId", psx.conv(u4, object.actorId));
            m.unkC = object.unk11;
            m.unkD = psx.conv(u8, c.func_800A152C(object.actorId, object.unk11, 0));
            pass.* = 0;
            return 0;
        },
        .parse => {},
    }

    // A pass other than 0 and 1 parses into the slot as it is (null: the C crashes on it).
    const m = model.?;
    const file = wep_file.decode(data) orelse return -2;
    @as(*align(1) c_int, @ptrCast(&m.nBones)).* = file.n_bones;
    @as(*align(1) c_int, @ptrCast(&m.nQuads)).* = file.n_quads;

    var buf: ?*v._wepModelOffsets = null;
    if (object.index == 0) {
        buf = v.g.vs_battle_commonWepBuffs()[0];
    } else if (object.index == 1) {
        buf = v.g.vs_battle_commonWepBuffs()[1];
    }
    var dst = buf;
    if (dst == null) dst = @ptrCast(@alignCast(c.vs_main_allocHeap(psx.conv(c_uint, file.offsets_size))));
    _ = memcpy(dst, file.offsets, intBits(file.offsets_size));
    psx.put(&m.offsets, dst);
    if (dst == null) return -2;

    const texW = file.tex_width;
    const textures = v.g.vs_battle_wepTextures();
    // the slot (or the page's pair, for a wide texture) from native_model's search of the slot records' counts, marked taken
    const wide = @as(c_int, @bitCast(texW)) >= 65;
    psx.setBits(m, "isWideTexture", @intFromBool(wide));
    const i: c_int = c.pc_nm_weapon_slots_take(&psx.at(textures, 0).refCount, @sizeOf(@TypeOf(psx.at(textures, 0).*)), @intFromBool(wide));
    if (i < 0) return -2;

    m.texSlot = psx.conv(u8, i);
    m.clutSlotOffset = psx.conv(u8, @as(c_int, object.unk11) +% (@as(c_int, object.actorId) << 1) +% 16);
    if (file.doublePalette()) {
        psx.setBits(m, "isDoubleClut", 1);
        m.nClutColors = 96;
    } else {
        psx.setBits(m, "isDoubleClut", 0);
        m.nClutColors = 48;
    }
    // the palettes into the model slot and the texels into the texture slot, from the file decoded by native_model
    if (c.pc_nm_wep_load_texture(file.offsets - 0x10, i, &m.unk440, &m.palettes, @sizeOf(@TypeOf(m.palettes[0]))) != 0) return -2;
    pass.* = 1;
    return -1;
}
