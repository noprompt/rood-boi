//! zig_diff spec: func_800D4720 -> func_800D4720.func_800D4720 (5BF94.c).
//! Inputs: one D_800F53B8_t in the arena with random bytes (its unkA, the
//! field the C stores to, and the rest of the object). The callee
//! func_800D5198 is a recording stub: it returns any u16, and it writes
//! unk8 and unkA of the object it is passed, so a port that reads unkA
//! before the store, or drops the store, is caught. Some inputs start with
//! unkA zero, some with random bits. The C has no branches or comparisons.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D4720));

pub const classes = [_][:0]const u8{ "unkA-zero", "unkA-random" };

pub const stubs = struct {
    pub fn func_800D5198(ctx: *zd.Ctx, p: anytype) u16 {
        const a: *v.D_800F53B8_t = @ptrCast(@alignCast(p));
        a.unk8 = ctx.value(u8);
        a.unkA = ctx.value(u16);
        return ctx.value(u16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.D_800F53B8_t);
    if (ctx.chance(4)) obj.unkA = 0;
    return .{obj};
}

pub fn classify(args: Args) usize {
    return if (args[0].?.unkA == 0) 0 else 1;
}
