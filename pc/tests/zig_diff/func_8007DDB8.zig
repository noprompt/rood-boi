//! zig_diff spec: func_8007DDB8 -> func_8007DDB8.func_8007DDB8 (146C.c).
//! Inputs: a D_800F1A68_t in the arena whose unk0/unk4 are picked from the
//! edges 0, +-1 and the i32 extremes (or both 0), and whose unk8/unkC are
//! random, so a port that copies the wrong fields is caught. The random
//! D_800F1A30 table (4 entries) is compared in full, so a store that lands
//! on the wrong index, or a stray write to entries 2 and 3, is caught too.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DDB8));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg = ctx.alloc(v.D_800F1A68_t);
    arg.unk0 = ctx.pick(i32, &.{ 0, -1, 1, std.math.minInt(i32), std.math.maxInt(i32) });
    arg.unk4 = ctx.pick(i32, &.{ 0, -1, 1, std.math.minInt(i32), std.math.maxInt(i32) });
    arg.unk8 = ctx.int(i32);
    arg.unkC = ctx.int(i32);
    if (ctx.chance(5)) {
        arg.unk0 = 0;
        arg.unk4 = 0;
    }
    return .{arg};
}

pub fn classify(args: Args) usize {
    const a = args[0].?;
    if (a.unk0 == 0 and a.unk4 == 0) return 0;
    if (a.unk0 < 0 or a.unk4 < 0) return 1;
    return 2;
}
