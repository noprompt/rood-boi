//! zig_diff spec: func_8007C1D8 -> func_8007C1D8.func_8007C1D8 (146C.c).
//! Inputs: vs_battle_actors (16 entries) each either NULL or an arena actor, so
//! every index 0..15 the C reads is safe, and an index 0..15 (the C has no
//! bounds check, so only in-table indices are built). arg1 is 0, 1, -1,
//! INT_MIN or INT_MAX, covering zero, nonzero without the sign bit, and nonzero
//! with it. Classes: the selected entry NULL, the entry set with arg1 == 0, and
//! the entry set with arg1 != 0.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C1D8));

pub const classes = [_][:0]const u8{ "null-entry", "entry-arg1-zero", "entry-arg1-nonzero" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        if (ctx.chance(4)) {
            table[i] = null;
        } else {
            table[i] = ctx.alloc(v.vs_battle_actor);
        }
    }
    const idx = ctx.range(c_int, 0, 15);
    const arg1 = ctx.pick(c_int, &.{ 0, 1, -1, std.math.minInt(c_int), std.math.maxInt(c_int) });
    return .{ idx, arg1 };
}

pub fn classify(args: Args) usize {
    const entry = v.g.vs_battle_actors()[@intCast(args[0])];
    if (entry == null) return 0;
    return if (args[1] == 0) 1 else 2;
}
