//! Draws one segment of an effect trail (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).
const std = @import("std");
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");
const sprite_item = common.sprite_item;

/// orig: func_800CDCBC (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// Projects the segment's four points (RotAverage4) and, inside the depth range, adds a quad: Gouraud from table D_800EC308 (config 6, through func_800CF988), else textured from D_800EC2E8, the head and tail brightnesses scaling the colours.
pub fn func_800CDCBC(trail: ?*v.effectTrailState, head: c_int, tail: c_int) callconv(.c) void {
    const t = trail.?;
    var xy: [4]c_int = undefined;
    const depth = c.RotAverage4(@ptrCast(&t.previousFirst), @ptrCast(&t.currentFirst), @ptrCast(&t.previousSecond), @ptrCast(&t.currentSecond), &xy[0], &xy[1], &xy[2], &xy[3], &t.projectionDepth, &t.projectionFlags);
    if (psx.conv(c_uint, depth -% 17) >= 2031) {
        return;
    }
    const color: usize = psx.getBits(&t.config.bits, "color");
    var rgb: [4]c_int = undefined;
    var uv: [4]c_int = undefined;
    if ((t.config.value & 0xF00000) == 0x600000) {
        // Gouraud, opaque, from the frame buffer: its texels are where the corners are (func_800CF988 sets them and the page).
        const table = v.g.D_800EC308();
        var record: v.func_800CF988_t = std.mem.zeroes(v.func_800CF988_t);
        const head_c = [3]u8{ psx.conv(u8, @as(c_int, table[color].r) *% head -% 128), psx.conv(u8, @as(c_int, table[color].@"g") *% head -% 128), psx.conv(u8, @as(c_int, table[color].b) *% head -% 128) };
        const tail_c = [3]u8{ psx.conv(u8, @as(c_int, table[color].r) *% tail -% 128), psx.conv(u8, @as(c_int, table[color].@"g") *% tail -% 128), psx.conv(u8, @as(c_int, table[color].b) *% tail -% 128) };
        for (0..4) |k| {
            record.unk8[k].unk4 = psx.conv(i16, xy[k]);
            record.unk8[k].unk6 = psx.conv(i16, xy[k] >> 16);
            const c3 = if (k < 2) head_c else tail_c;
            rgb[k] = @as(c_int, c3[0]) | (@as(c_int, c3[1]) << 8) | (@as(c_int, c3[2]) << 16);
        }
        c.func_800CF988(@ptrCast(&record), head, head, 0);
        for (0..4) |k| uv[k] = @as(c_int, @as(u16, @bitCast(record.unk8[k].unk8)));
        sprite_item.gt4(depth, false, @as(c_int, @as(u16, @bitCast(record.unk8[1].unkA))), 0, &rgb, &xy, &uv);
    } else {
        // Semi-transparent, textured from D_800EC2E8's page 0x38 (0x58 for config 7) and CLUT 0x3C30, the head's and tail's brightness scaling the colour.
        const page: c_int = if ((t.config.value & 0xF0000) != 0x70000) 0x38 else 0x58;
        const texture: c_uint = psx.getBits(&t.config.bits, "texture");
        const column = psx.conv(u8, texture % 3);
        const row = psx.conv(u8, texture / 3);
        const base: u16 = psx.conv(u16, @as(c_int, column) * 2560 + @as(c_int, row) * 40);
        uv = .{ @as(c_int, base +% 0x4868), @as(c_int, base +% 0x4F68), @as(c_int, base +% 0x4887), @as(c_int, base +% 0x4F87) };
        const table = v.g.D_800EC2E8();
        for (0..4) |k| {
            const weight: c_int = if (k < 2) head else tail;
            const r = psx.conv(u8, @divTrunc(@as(c_int, table[color].r) *% weight, 8));
            const g = psx.conv(u8, @divTrunc(@as(c_int, table[color].@"g") *% weight, 8));
            const b = psx.conv(u8, @divTrunc(@as(c_int, table[color].b) *% weight, 8));
            rgb[k] = @as(c_int, r) | (@as(c_int, g) << 8) | (@as(c_int, b) << 16);
        }
        sprite_item.gt4(depth, true, page, 0x3C30, &rgb, &xy, &uv);
    }
}
