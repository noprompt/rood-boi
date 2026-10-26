//! zig_diff spec: func_8007DD50 -> func_8007DD50.func_8007DD50 (146C.c).
//! Inputs: arg0 zero (about a quarter of runs) and nonzero, with positive,
//! negative and extreme values, so the `!= 0` test sees both signs. The
//! global D_800F1ABC is null or points at an arena block, so the NULL test
//! takes both sides. vs_main_allocHeapR is a recording stub that returns
//! null sometimes (the C stores it unchecked) and an arena block otherwise.
//! func_8007D41C may overwrite D_800F1B98, as a real callee could.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DD50));

pub const classes = [_][:0]const u8{ "arg-zero", "nonzero-null-slot", "nonzero-live-slot" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg: c_int = if (ctx.chance(4))
        0
    else
        ctx.pick(c_int, &.{ 1, -1, 2, 0x7fffffff, -0x80000000 });
    if (ctx.chance(2)) {
        v.g.D_800F1ABC().* = null;
    } else {
        v.g.D_800F1ABC().* = ctx.alloc(v.D_800F1ABC_t);
    }
    return .{arg};
}

pub fn classify(args: Args) usize {
    if (args[0] == 0) return 0;
    return if (v.g.D_800F1ABC().* == null) 1 else 2;
}

pub const stubs = struct {
    pub fn vs_main_allocHeapR(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        _ = size;
        if (ctx.value(u2) == 0) return null;
        return @ptrCast(ctx.alloc(v.D_800F1ABC_t));
    }

    pub fn func_8007D41C(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g.D_800F1B98().* = ctx.value(i32);
    }
};
