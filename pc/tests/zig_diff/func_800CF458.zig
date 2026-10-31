//! zig_diff spec: func_800CF458 -> func_800CF458.func_800CF458 (5BF94.c).
//! Inputs: a func_800CF0E8_t in the arena or a null pointer, and two random c_ints
//! with edge values. The C is a single forwarding call to func_800CF218. Here that
//! callee is a recording stub: it returns any byte (the C's int return is that byte
//! zero-extended) and may write the object it is given, which the C never reads back.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF458));

pub const classes = [_][:0]const u8{ "null-object", "object" };

pub const stubs = struct {
    pub fn func_800CF218(ctx: *zd.Ctx, arg0: anytype, arg1: anytype, arg2: anytype) u8 {
        _ = arg1;
        _ = arg2;
        if (arg0) |p| {
            const obj: *v.func_800CF0E8_t = @ptrCast(@alignCast(p));
            obj.unk6 = ctx.value(i16);
        }
        return ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj: ?*v.func_800CF0E8_t = if (ctx.chance(4)) null else ctx.alloc(v.func_800CF0E8_t);
    const a = ctx.pick(c_int, &.{ 0, 1, -1, 255, 256, 0x7fffffff, -0x80000000 });
    const b = ctx.pick(c_int, &.{ 0, 1, -1, 128, 255, 0x7fffffff, -0x80000000 });
    return .{ obj, a, b };
}

pub fn classify(args: Args) usize {
    return if (args[0] == null) 0 else 1;
}
