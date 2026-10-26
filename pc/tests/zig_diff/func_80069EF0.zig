//! zig_diff spec: func_80069EF0 -> func_80069EF0.func_80069EF0 (146C.c).
//! Inputs: the current set D_80061078[D_80060064] (index 0..3) with its eight
//! slot tags and its round-robin cursor unk4. Hits: a slot tag equals arg0+1
//! (arg0 at the edges -1, 0, 1, 100, 254), at one slot or two, the second
//! later so `break` matters, and at slot 7 so `i < 8` matters. Misses: no tag
//! equals arg0+1, with the cursor at 7 (wrap), below 7, at 8 (out of range,
//! inside the global for index 0..2), and near 2^32 (the signed/unsigned
//! compare of the cursor). The C only computes pointers on the miss path, so
//! the out-of-range cursors never dereference.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80069EF0));

pub const classes = [_][:0]const u8{ "hit", "miss-wrap", "miss-slot", "miss-index-8", "miss-high" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const mode = ctx.range(u8, 0, 9);
    const idx: i32 = if (mode == 8) ctx.range(i32, 0, 2) else ctx.range(i32, 0, 3);
    v.g.D_80060064().* = idx;
    const set = &v.g.D_80061078()[@intCast(idx)];

    const hit = mode <= 4;
    const arg0: c_int = if (hit) ctx.edge(c_int, &.{ -1, 0, 1, 100, 254 }) else ctx.range(c_int, -5, 300);
    const want = arg0 +% 1;

    // Clear every tag equal to the wanted one, so misses really miss.
    for (&set.unk8) |*slot| {
        if (@as(i32, slot[0]) == want) slot[0] +%= 1;
    }

    if (hit) {
        const k = ctx.range(usize, 0, 7);
        set.unk8[k][0] = @intCast(want);
        if (k < 7 and ctx.chance(3)) {
            const j = ctx.range(usize, k + 1, 7);
            set.unk8[j][0] = @intCast(want);
        }
        set.unk4 = ctx.range(u32, 0, 7);
    } else {
        set.unk4 = switch (mode) {
            5 => 7,
            6, 7 => ctx.range(u32, 0, 6),
            8 => 8,
            else => ctx.edge(u32, &.{ 0xFFFF_FFF0, 0xFFFF_FFFE }),
        };
    }
    return .{arg0};
}

pub fn classify(args: Args) usize {
    const arg0 = args[0];
    const set = &v.g.D_80061078()[@intCast(v.g.D_80060064().*)];
    const want = arg0 +% 1;
    for (&set.unk8) |*slot| {
        if (@as(i32, slot[0]) == want) return 0;
    }
    const k = set.unk4;
    if (k >= 0x8000_0000) return 4;
    if (k == 8) return 3;
    if (k == 7) return 1;
    return 2;
}
