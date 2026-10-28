//! zig_diff spec: func_8008C070 -> func_8008C070.func_8008C070 (146C.c).
//! Inputs: the frame counter D_800F1D6A at edges (0, -1, 32767, -32768) so the
//! increment wraps. The slot table has its first free entry (unk0 == 0) at
//! any of 0..7, or no free entry in a quarter of runs (the loop then exits
//! with i == 8). Occupied entries are nonzero and include negative values;
//! entries after the free one are sometimes zero, so a `continue` would fill
//! them. arg0 is any int, and arg1 is an arena object or null.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008C070));

pub const classes = [_][:0]const u8{ "full", "slot-0", "slot-1-3", "slot-4-6", "slot-7" };

const busy_edges = [_]i32{ -1, 1, 0x7fff_ffff, std.math.minInt(i32) };

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.D_800F1D28();
    v.g.D_800F1D6A().* = ctx.pick(i16, &.{ 0, -1, 32767, -32768 });

    // 8 means no free entry at all.
    const slot: usize = if (ctx.chance(4)) 8 else ctx.range(usize, 0, 7);
    for (table, 0..) |*e, i| {
        if (i == slot) {
            e.unk0 = 0;
        } else if (i < slot) {
            e.unk0 = ctx.edge(i32, &busy_edges);
        } else {
            e.unk0 = if (ctx.chance(2)) 0 else ctx.edge(i32, &busy_edges);
        }
    }

    const arg1: ?*v._mpdRoomSectionA = if (ctx.chance(5)) null else ctx.alloc(v._mpdRoomSectionA);
    return .{ ctx.int(c_int), arg1 };
}

pub fn classify(args: Args) usize {
    _ = args;
    const table = v.g.D_800F1D28();
    for (table, 0..) |e, i| {
        if (e.unk0 == 0) {
            return if (i == 0) 1 else if (i <= 3) 2 else if (i <= 6) 3 else 4;
        }
    }
    return 0;
}
