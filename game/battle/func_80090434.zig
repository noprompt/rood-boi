//! The sparkle particles: they drift on the view and are drawn as one or two tiles each (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80090434 (src/BATTLE/BATTLE.PRG/146C.c)
/// Moves each particle on the view and draws it as one or two tiles into the ordering table.
pub fn func_80090434() callconv(.c) void {
    const scratch: *v.vs_scratch_t = @ptrFromInt(0x1F800000);

    c.SetRotMatrix(psx.cptr(c.MATRIX, &scratch.viewMatrix));
    c.SetTransMatrix(psx.cptr(c.MATRIX, &scratch.viewMatrix));

    var origin: v.VECTOR = undefined;
    var velocity: v.VECTOR = undefined;
    var flags: c.psx_long = undefined;
    c.RotTrans(@ptrCast(v.g.D_800F1CE0()), psx.cptr(c.VECTOR, &origin), &flags);
    c.RotTrans(@ptrCast(v.g.D_800F1D98()), psx.cptr(c.VECTOR, &velocity), &flags);

    var cursor: usize = @intFromPtr(psx.get(scratch.unk0));
    origin.vx = (velocity.vx -% origin.vx) >> 3;
    origin.vy = (velocity.vy -% origin.vy) >> 3;
    origin.vz = (velocity.vz -% origin.vz) >> 3;

    if (v.g.D_800F1BA4().* == 0) {
        if (v.g.D_800F1DC7().* != 0) {
            v.g.D_800F1DC7().* -%= 8;
        }
    } else if (v.g.D_800F1DC7().* < 96) {
        v.g.D_800F1DC7().* +%= 8;
    }

    var particleAddr: usize = @intFromPtr(v.g.D_800F1DD4().*);
    var particle: *allowzero align(1) v.D_800F1DD4_t = @ptrFromInt(particleAddr);
    var prim: usize = cursor;

    flags = 0;
    while (flags < v.g.D_800F1DC0().*) : ({
        flags +%= 1;
        particleAddr +%= @sizeOf(v.D_800F1DD4_t);
        particle = @ptrFromInt(particleAddr);
    }) {
        if (v.g.D_800F1BA4().* == 0) {
            var j: c_int = 0;
            while (j < (v.g.vs_gametime_tickspeed().* >> 1)) : (j +%= 1) {
                particle.unkF = psx.conv(u8, @as(c_int, particle.unkF) +% ((c.rand() & 15) -% 7));
                particle.unkF &= 127;
                if (particle.unkD != 0) {
                    particle.unk0 = psx.conv(i16, @as(c_int, particle.unk0) +%
                        (origin.vx +% (c.rsin(@as(c_int, particle.unkF) << 5) >> 9)));
                    particle.unk4 = psx.conv(i16, @as(c_int, particle.unk4) +%
                        (origin.vz -% (c.rcos(@as(c_int, particle.unkF) << 5) >> 9)));
                    particle.unk2 = psx.conv(i16, @as(c_int, particle.unk2) -%
                        (c.rsin(@as(c_int, particle.unkD) << 6) >> 9));
                    particle.unkD +%= 1;
                    if (particle.unkD > 32) {
                        particle.unkD = 0;
                    }
                } else {
                    particle.unk0 = psx.conv(i16, @as(c_int, particle.unk0) +%
                        (origin.vx +% (c.rsin(@as(c_int, particle.unkF) << 5) >> 10)));
                    particle.unk4 = psx.conv(i16, @as(c_int, particle.unk4) +%
                        (origin.vz -% (c.rcos(@as(c_int, particle.unkF) << 5) >> 10)));
                    if ((c.rand() & 127) == 0) {
                        particle.unkD = 1;
                    }
                }
                particle.unk2 = psx.conv(i16, @as(c_int, particle.unk2) +% origin.vy);
                particle.unk4 &= 255;
                if (particle.unk0 < 0) {
                    particle.unk0 = psx.conv(i16, @as(c_int, particle.unk0) +% 320);
                }
                if (particle.unk0 > 320) {
                    particle.unk0 = psx.conv(i16, @as(c_int, particle.unk0) -% 320);
                }
                if (particle.unk2 < 0) {
                    particle.unk2 = psx.conv(i16, @as(c_int, particle.unk2) +% 240);
                }
                if (particle.unk2 > 240) {
                    particle.unk2 = psx.conv(i16, @as(c_int, particle.unk2) -% 240);
                }
            }
        }

        const x: c_int = @divTrunc((@as(c_int, particle.unk0) -% 160) << 12,
            (@as(c_int, particle.unk4) << 2) +% 3072) +% 160;
        const y: c_int = @divTrunc((@as(c_int, particle.unk2) -% 120) << 12,
            (@as(c_int, particle.unk4) << 2) +% 3072) +% 120;
        const brightness = @divTrunc(255 -% @as(c_int, particle.unk4), 4);
        const fade = @as(c_int, v.g.D_800F1DC7().*) -% 32;
        var color: c_int = brightness -% fade;
        if (color < 0) {
            color = 0;
        }

        if (psx.conv(c_uint, x) < 320 and psx.conv(c_uint, y) < 240) {
            const tag: *allowzero align(1) v.P_TAG = @ptrFromInt(prim);
            const tile: *allowzero align(1) v.TILE = @ptrFromInt(prim);
            psx.setBits(tag, "len", 3);
            tag.code = 0x60;
            tag.code |= 0x02;
            tile.x0 = psx.conv(i16, x);
            tile.y0 = psx.conv(i16, y);
            if ((flags & 1) != 0) {
                tile.w = 2;
                tile.h = 2;
            } else {
                tile.w = 1;
                tile.h = 1;
            }
            tile.r0 = psx.conv(u8, color);
            tile.g0 = psx.conv(u8, color);
            tile.b0 = psx.conv(u8, color);
            c.AddPrim(@ptrFromInt(@intFromPtr(psx.get(scratch.unk4)) +% 4 * @sizeOf(c_uint)), @ptrFromInt(prim));
            prim +%= @sizeOf(v.TILE);
            cursor +%= @sizeOf(v.TILE);
        }

        if (psx.conv(u16, particle.unk8) < 320 and psx.conv(u16, particle.unkA) < 240) {
            {
                const tag: *allowzero align(1) v.P_TAG = @ptrFromInt(prim);
                const tile: *allowzero align(1) v.TILE = @ptrFromInt(prim);
                psx.setBits(tag, "len", 3);
                tag.code = 0x60;
                tag.code |= 0x02;
                tile.x0 = particle.unk8;
                tile.y0 = particle.unkA;
                color >>= 1;
                if ((flags & 1) != 0) {
                    tile.w = 2;
                    tile.h = 2;
                } else {
                    tile.w = 1;
                    tile.h = 1;
                }
                tile.r0 = psx.conv(u8, color);
                tile.g0 = psx.conv(u8, color);
                tile.b0 = psx.conv(u8, color);
                c.AddPrim(@ptrFromInt(@intFromPtr(psx.get(scratch.unk4)) +% 4 * @sizeOf(c_uint)), @ptrFromInt(prim));
                prim +%= @sizeOf(v.TILE);
                cursor +%= @sizeOf(v.TILE);
            }
            {
                const tag: *allowzero align(1) v.P_TAG = @ptrFromInt(prim);
                const tile: *allowzero align(1) v.TILE = @ptrFromInt(prim);
                psx.setBits(tag, "len", 3);
                tag.code = 0x60;
                tag.code |= 0x02;
                tile.x0 = psx.conv(i16, x -% ((x -% @as(c_int, particle.unk8)) *% 2));
                tile.y0 = psx.conv(i16, y -% ((y -% @as(c_int, particle.unkA)) *% 2));
                color >>= 1;
                if ((flags & 1) != 0) {
                    tile.w = 2;
                    tile.h = 2;
                } else {
                    tile.w = 1;
                    tile.h = 1;
                }
                tile.r0 = psx.conv(u8, color);
                tile.g0 = psx.conv(u8, color);
                tile.b0 = psx.conv(u8, color);
                c.AddPrim(@ptrFromInt(@intFromPtr(psx.get(scratch.unk4)) +% 4 * @sizeOf(c_uint)), @ptrFromInt(prim));
                prim +%= @sizeOf(v.TILE);
                cursor +%= @sizeOf(v.TILE);
            }
        }

        if (v.g.D_800F1BA4().* == 0) {
            particle.unk8 = psx.conv(i16, x);
            particle.unkA = psx.conv(i16, y);
        }
    }

    psx.put(&scratch.unk0, @as(?*anyopaque, @ptrFromInt(cursor)));
    c.pc_insert_tpage(4, 0x31);
}
