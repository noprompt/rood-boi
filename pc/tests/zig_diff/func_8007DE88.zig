//! zig_diff spec: func_8007DE88 -> func_8007DE88.func_8007DE88 (146C.c).
//! Inputs: D_800F1A30[0] takes edge values (0, -1, 1, INT_MAX, INT_MIN) and
//! arg0 is either a fresh arena block of three ints or the global table
//! itself, so the three stores alias the entries the C reads. The C has no
//! branches and no calls, so the classes only split the aliasing case.
const zd = @import("zdiff");
const std = @import("std");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DE88));

pub const classes = [_][:0]const u8{ "arena", "aliased-global" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = v.g.D_800F1A30();
    d[0] = ctx.pick(i32, &.{ 0, -1, 1, 0x7fffffff, -2147483648 });
    if (ctx.chance(3)) {
        const p: [*c]c_int = @ptrCast(d);
        return .{p};
    }
    const out = ctx.alloc([3]c_int);
    const p: [*c]c_int = @ptrCast(out);
    return .{p};
}

pub fn classify(args: Args) usize {
    const d = v.g.D_800F1A30();
    return if (@intFromPtr(args[0]) == @intFromPtr(d)) 1 else 0;
}
