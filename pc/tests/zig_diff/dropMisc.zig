//! zig_diff spec: _dropMisc -> drop_misc.dropMisc (146C.c).
//! Inputs: a loot block and a two-entry uiMisc list in the arena. Each list
//! entry's id is zero or one of several nonzero values (with and without the
//! sign bit, and 0x8000 whose low byte is zero), counts are any byte, and in
//! about a fifth of the runs the list lies inside the loot block (at an even
//! byte offset), so the stores into looted->misc overwrite list entries the C
//! has yet to read.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").dropMisc));

pub const classes = [_][:0]const u8{ "overlap", "none", "first-only", "second-only", "both" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const loot_size = @sizeOf(v.vs_battle_loot);
    const buf = ctx.allocBytes(loot_size + 64, 16);
    const looted: *v.vs_battle_loot = @ptrCast(@alignCast(buf));
    const overlap = ctx.chance(5);
    const base_bytes: [*]u8 = if (overlap)
        buf + 2 * ctx.range(usize, 0, loot_size / 2)
    else
        ctx.allocBytes(2 * @sizeOf(v.vs_battle_uiMisc), 16);
    const base: *v.vs_battle_uiMisc = @ptrCast(@alignCast(base_bytes));
    const list: [*]v.vs_battle_uiMisc = @ptrCast(base);
    for (0..2) |i| {
        list[i].id = if (ctx.chance(3))
            0
        else
            ctx.pick(u16, &.{ 1, 0x100, 0x7FFF, 0x8000, 0xFFFF });
        list[i].count = ctx.int(u8);
        list[i].unk3 = ctx.int(u8);
    }
    return .{ looted, base };
}

pub fn classify(args: Args) usize {
    const lo = @intFromPtr(args[0].?);
    const bo = @intFromPtr(args[1].?);
    if (bo >= lo and bo < lo + @sizeOf(v.vs_battle_loot)) return 0;
    const list: [*]v.vs_battle_uiMisc = @ptrCast(args[1].?);
    const first = list[0].id != 0;
    const second = list[1].id != 0;
    if (first and second) return 4;
    if (first) return 2;
    if (second) return 3;
    return 1;
}
