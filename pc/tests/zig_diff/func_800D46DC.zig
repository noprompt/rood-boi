//! zig_diff spec: func_800D46DC -> func_800D46DC.func_800D46DC (5BF94.c).
//! Inputs: a random D_800F53B8_t whose unkA is an edge value (0, 1, 0x7FFF,
//! 0x8000, 0xFFFD, 0xFFFE, 0xFFFF, so the +2 wraps), and arg0 from the edges
//! 0, 1, -1, INT_MIN, INT_MAX (zero and nonzero with and without the sign bit).
//! The callee is a recording stub that sometimes rewrites unk8 and returns any
//! u16, so the port must store the returned value and not a guess.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D46DC));

pub const classes = [_][:0]const u8{ "call-branch", "add-no-wrap", "add-wraps" };

pub const stubs = struct {
    pub fn func_800D5198(ctx: *zd.Ctx, p: anytype) u16 {
        const obj: *v.D_800F53B8_t = @ptrCast(@alignCast(p.?));
        // The callee may rewrite the object it was passed.
        if (ctx.value(u8) < 64) obj.unk8 = ctx.value(u8);
        return ctx.value(u16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.D_800F53B8_t);
    obj.unkA = ctx.pick(u16, &.{ 0, 1, 0x7FFF, 0x8000, 0xFFFD, 0xFFFE, 0xFFFF });
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, std.math.minInt(c_int), std.math.maxInt(c_int) });
    return .{ arg0, obj };
}

pub fn classify(args: Args) usize {
    if (args[0] != 0) return 0;
    if (args[1].?.unkA >= 0xFFFE) return 2;
    return 1;
}
