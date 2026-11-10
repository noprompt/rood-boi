//! The rain: falling drops as lines, landed drops as splashes (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");
const sprite_item = @import("common").sprite_item;

/// `ot + depth` with the C's 4-byte u_long entries.
fn ordering(scratch: *v.vs_scratch_t, depth: c_int) ?*anyopaque {
    return @ptrCast(psx.at(@as([*]u32, @ptrCast(@alignCast(psx.get(scratch.unk4).?))), depth));
}

/// orig: func_8008F440 (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// For each of the D_800F1DC0 drops: a falling drop moves by the wind D_800F1D98 per tick (its fall scaled by its
/// unkE) and, when it projects on screen, is drawn as a semi-transparent line back along the wind; off screen (or
/// too near or far) it is recycled (func_80090A1C). A drop above the floor that was drawn on an odd slot lands
/// where its cell (func_8008B764) is not a hole, at the floor height (func_8008DC7C). A landed drop is drawn as a
/// growing splash quad (frame unkD / 2) and recycled after 8 frames or off screen.
pub fn func_8008F440() callconv(.c) void {
    var vertices: [10]v.SVECTOR = undefined;
    var projection: c_int = undefined;
    var flags: c_int = undefined;
    const scratch: *v.vs_scratch_t = @ptrFromInt(0x1F800000);
    c.SetRotMatrix(@ptrCast(&v.g.vs_view().viewMatrix));
    c.SetTransMatrix(@ptrCast(&v.g.vs_view().viewMatrix));
    const wind = v.g.D_800F1D98();
    var particle: [*]v.D_800F1DD4_t = @ptrCast(v.g.D_800F1DD4().*.?);
    var i: c_int = 0;
    while (i < v.g.D_800F1DC0().*) : ({
        i += 1; // i < a short
        particle += 1;
    }) {
        const drop = &particle[0];
        if (drop.unkC == 0) {
            if (v.g.D_800F1BA4().* == 0) {
                var j: c_int = 0;
                while (j < (v.g.vs_gametime_tickspeed().* >> 1)) : (j += 1) { // j < an int
                    // x86 shifts by the amount & 31 (unkE is 0 or 2 here).
                    drop.unk2 = psx.conv(i16, @as(c_int, drop.unk2) +% (@as(c_int, wind[1]) << @truncate(drop.unkE)));
                    if (drop.unkE == 0) {
                        drop.unk0 = psx.conv(i16, @as(c_int, drop.unk0) +% wind[0]);
                        drop.unk4 = psx.conv(i16, @as(c_int, drop.unk4) +% wind[2]);
                    }
                }
            }
            drop.unkE = 2;
            var sxy0: c_int = 0;
            const depth = c.RotTransPers(@ptrCast(drop), @ptrCast(&sxy0), &projection, &flags);
            if (psx.conv(u16, @as(c_int, psx.conv(i16, sxy0)) +% 639) < 1599 and depth < 2048) {
                if (psx.conv(c_uint, (sxy0 >> 16 & 0xFFFF) - 1) < 239 and psx.conv(i16, sxy0) > 0 and
                    psx.conv(i16, sxy0) < 320 and depth > 4)
                {
                    vertices[0].vx = psx.conv(i16, @as(c_int, drop.unk0) -% wind[0]);
                    vertices[0].vy = psx.conv(i16, @as(c_int, drop.unk2) -% wind[1]);
                    vertices[0].vz = psx.conv(i16, @as(c_int, drop.unk4) -% wind[2]);
                    var sxy1: c_int = 0;
                    _ = c.RotTransPers(@ptrCast(&vertices[0]), @ptrCast(&sxy1), &projection, &flags);
                    // The drop: a semi-transparent shaded line back along the wind; left out of the hardware picture where room
                    // geometry hides it (environment.cpp), as it always was.
                    const item = sprite_item.lineG2(ordering(scratch, depth), true, 96 | (96 << 8) | (128 << 16), sxy0, 32 | (32 << 8) | (100 << 16), sxy1);
                    if (c.pc_weather_drop_hidden(drop.unk0, drop.unk2, drop.unk4) != 0) sprite_item.hardwareHidden(item);
                    c.pc_insert_tpage(depth, 96);
                    drop.unkE = 0;
                }
            } else {
                c.func_80090A1C(@ptrCast(drop));
            }
            if (drop.unk2 > 0) {
                if (drop.unkE == 0 and (i & 1) != 0) {
                    const cell = c.func_8008B764(psx.conv(c_uint, @divTrunc(@as(c_int, drop.unk0), 128)), psx.conv(c_uint, @divTrunc(@as(c_int, drop.unk4), 128)), 0);
                    if (cell != null and (@as(*u32, @ptrCast(@alignCast(cell))).* & 31) != 31) {
                        drop.unkC = 1;
                        projection = (@as(c_int, c.func_8008DC7C(drop.unk0, drop.unk4)) << 17) >> 17;
                        drop.unk2 = psx.conv(i16, projection);
                    } else {
                        c.func_80090A1C(@ptrCast(drop));
                    }
                } else {
                    c.func_80090A1C(@ptrCast(drop));
                }
            }
        } else {
            const corners = [4][2]c_int{ .{ -24, -24 }, .{ 24, -24 }, .{ -24, 24 }, .{ 24, 24 } };
            for (corners, 0..) |corner, k| {
                vertices[k].vx = psx.conv(i16, @as(c_int, drop.unk0) +% corner[0]);
                vertices[k].vy = drop.unk2;
                vertices[k].vz = psx.conv(i16, @as(c_int, drop.unk4) +% corner[1]);
            }
            var corners_xy: [4]c_int = .{ 0, 0, 0, 0 };
            var depth = c.RotTransPers4(@ptrCast(&vertices[0]), @ptrCast(&vertices[1]), @ptrCast(&vertices[2]), @ptrCast(&vertices[3]),
                @ptrCast(&corners_xy[0]), @ptrCast(&corners_xy[1]), @ptrCast(&corners_xy[2]), @ptrCast(&corners_xy[3]), &projection, &flags);
            depth -%= 64;
            if (psx.conv(c_uint, depth -% 1) < 2047) {
                // A semi-transparent splash quad: frame unkD / 2 of the strip.
                const frame: c_int = @as(c_int, drop.unkD >> 1) * 16;
                const item = sprite_item.ft4(ordering(scratch, depth), false, true, 0x71, 0x38BF, 0x808080, &corners_xy, &[4]c_int{
                    (frame & 0xFF) | (192 << 8), ((frame + 16) & 0xFF) | (192 << 8), (frame & 0xFF) | (208 << 8), ((frame + 16) & 0xFF) | (208 << 8),
                });
                if (c.pc_weather_drop_hidden(drop.unk0, drop.unk2, drop.unk4) != 0) sprite_item.hardwareHidden(item);
                if (v.g.D_800F1BA4().* == 0) {
                    drop.unkD = psx.conv(u8, @as(c_int, drop.unkD) +% (v.g.vs_gametime_tickspeed().* >> 1));
                }
                if (drop.unkD >= 8) {
                    c.func_80090A1C(@ptrCast(drop));
                }
            } else {
                c.func_80090A1C(@ptrCast(drop));
            }
        }
    }
}
