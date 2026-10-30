//! zig_diff spec: func_800CF3F8 -> func_800CF3F8.func_800CF3F8 (5BF94.c).
//! The C is a straight sequence: two scratchpad-free calls to func_800D1B18 on
//! the globals D_800F55A8 and D_800F54D8, one call to func_800D7890(0), then
//! func_800CF218(arg0, 0, arg1) whose u8 result is returned. The inputs cover
//! arg0 null and an arena object, and arg1 at 0, 1, -1, the 16-bit edges, the
//! 32-bit extremes and values above 16 bits (so a narrowing of arg1 shows).
//! The stubs write the callee-visible state (the object's effectId, the
//! global's roll) and return any u8, so a port that drops or reorders a call,
//! or narrows a value, is caught in the traces or the return value.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF3F8));

pub const classes = [_][:0]const u8{ "null-arg0", "arg1-zero", "arg1-negative", "arg1-positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj: ?*v.func_800CF0E8_t = if (ctx.chance(4)) null else ctx.alloc(v.func_800CF0E8_t);
    const arg1 = ctx.pick(c_int, &.{
        0,
        1,
        -1,
        0x7FFF,
        0x8000,
        -0x8000,
        0x10000,
        std.math.maxInt(c_int),
        std.math.minInt(c_int),
    });
    return .{ obj, arg1 };
}

pub fn classify(args: Args) usize {
    if (args[0] == null) return 0;
    if (args[1] == 0) return 1;
    if (args[1] < 0) return 2;
    return 3;
}

pub const stubs = struct {
    pub fn func_800CF218(ctx: *zd.Ctx, arg0: anytype, arg1: anytype, arg2: anytype) u8 {
        _ = arg1;
        _ = arg2;
        const obj: ?*v.func_800CF0E8_t = @ptrCast(@alignCast(arg0));
        if (obj) |o| {
            if (ctx.value(u1) == 1) o.effectId = ctx.value(u16);
        }
        return ctx.value(u8);
    }

    pub fn func_800D1B18(ctx: *zd.Ctx, p: anytype) void {
        const d: *v.D_800F54D8_t = @ptrCast(@alignCast(p));
        if (ctx.value(u1) == 1) d.roll = ctx.value(i32);
    }
};
