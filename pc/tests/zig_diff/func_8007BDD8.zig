//! zig_diff spec: func_8007BDD8 -> func_8007BDD8.func_8007BDD8 (146C.c).
//! Inputs: an arbitrary c_int, drawn from the sign and bit-0 edges (0, 1, -1,
//! INT_MAX, INT_MIN) and otherwise any value. The unit has no branches, so the
//! classes only split the bit-0 value the result is built from. The callee
//! func_8008C40C is a recording stub that sometimes overwrites
//! _firstPersonViewEnabled, the global the C stores its result into.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007BDD8));

pub const classes = [_][:0]const u8{ "bit0-clear", "bit0-set" };

pub const stubs = struct {
    pub fn func_8008C40C(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g._firstPersonViewEnabled().* = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    return .{ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000 })};
}

pub fn classify(args: Args) usize {
    return @as(usize, @intCast(args[0] & 1));
}
