//! zig_diff spec: func_800D47C8 -> func_800D47C8.func_800D47C8 (5BF94.c).
//! Inputs: the argument is null or an arena D_800F53B8_t with random bytes. The
//! C has no branches of its own: it calls func_800D5170 with the argument, stores
//! its u8 result into D_800F5610 (widened to i32) and returns 1. The callee stub
//! returns any u8 (so bit 7 is set about half the time) and may rewrite the
//! object's unk8 field, which the C never reads back.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D47C8));

pub const classes = [_][:0]const u8{ "null-arg", "object-arg" };

pub const stubs = struct {
    pub fn func_800D5170(ctx: *zd.Ctx, p: anytype) u8 {
        const a: ?*v.D_800F53B8_t = @ptrCast(@alignCast(p));
        if (a) |obj| {
            if (ctx.value(u1) == 1) obj.unk8 = ctx.value(u8);
        }
        return ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.D_800F53B8_t);
    if (ctx.chance(4)) return .{null};
    return .{obj};
}

pub fn classify(args: Args) usize {
    return if (args[0] == null) 0 else 1;
}
