//! zig_diff spec: func_8008EB04 -> func_8008EB04.func_8008EB04 (146C.c).
//! Inputs: two c_int objects in the arena, or one of them aliased to the
//! other (the second store wins), or the second one at the PS1 scratchpad.
//! The globals D_800F1DCA (u8, zero-extended) and D_800F1DC4 (i16,
//! sign-extended) keep their random bytes, so both sign cases occur.
//! The C has no branches and no comparisons: the classes only pick the
//! pointer relationship.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008EB04));

pub const classes = [_][:0]const u8{ "distinct", "aliased", "scratchpad" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const a = ctx.alloc(c_int);
    if (ctx.chance(4)) return .{ a, a };
    if (ctx.chance(8)) return .{ a, @ptrFromInt(zd.scratchpad) };
    const b = ctx.alloc(c_int);
    return .{ a, b };
}

pub fn classify(args: Args) usize {
    if (args[0] == args[1]) return 1;
    if (@intFromPtr(args[1]) == zd.scratchpad) return 2;
    return 0;
}
