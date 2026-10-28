//! zig_diff spec: func_800733F8 -> func_800733F8.func_800733F8 (146C.c).
//! Inputs: the effect id arg0 over zero, negative, positive and extreme values.
//! The C has no branches. Its observable effects are the request it passes to
//! func_800CF0E8 (copied into the arena by the stub, so every field, including
//! the ones the C zeroes, is compared), the stores to D_800F196C and
//! vs_gametime_tickspeed, and the order and arguments of the three calls. The
//! stubs write D_800F196C and tickspeed sometimes and return ctx.value.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800733F8));

pub const classes = [_][:0]const u8{ "zero", "negative", "positive" };

/// The arena copy of the request func_800CF0E8 receives in the current iteration.
var seen: ?*v.func_800CF0E8_t = null;

pub fn prepare(ctx: *zd.Ctx) Args {
    seen = ctx.alloc(v.func_800CF0E8_t);
    const arg0 = ctx.pick(c_int, &.{ 0, 1, 4, -1, 0x7fff_ffff, -2147483648 });
    return .{arg0};
}

pub fn classify(args: Args) usize {
    const arg0 = args[0];
    if (arg0 == 0) return 0;
    if (arg0 < 0) return 1;
    return 2;
}

pub const stubs = struct {
    pub fn func_800CF0E8(ctx: *zd.Ctx, req: anytype, a: anytype, b: anytype) c_int {
        _ = a;
        _ = b;
        const r: *const v.func_800CF0E8_t = @ptrCast(@alignCast(req));
        seen.?.* = r.*;
        if (ctx.value(u1) == 1) v.g.D_800F196C().* = ctx.value(u32);
        return ctx.value(c_int);
    }

    pub fn func_800CB654(ctx: *zd.Ctx, arg: anytype) void {
        _ = arg;
        if (ctx.value(u1) == 1) v.g.vs_gametime_tickspeed().* = ctx.value(i32);
    }

    pub fn func_8008B4C8(ctx: *zd.Ctx, arg: anytype) c_int {
        _ = arg;
        return ctx.value(c_int);
    }
};
