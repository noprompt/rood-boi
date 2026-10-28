//! zig_diff spec: func_8007E97C -> func_8007E97C.func_8007E97C (146C.c).
//! The C returns 100 when the global D_800F1A04 is nonzero and 255 when it is
//! zero; the three arguments are unused. Inputs: D_800F1A04 is set to zero,
//! to a value whose low 16 bits are zero but which is nonzero (only the high
//! half set, including the sign bit), or to a value with low bits set (random
//! or the sign bit alone). The argument pointers are null or arena objects,
//! and the integer arguments are random, since the C never reads them.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007E97C));

pub const classes = [_][:0]const u8{ "global-zero", "nonzero-low-half-zero", "nonzero-low-bits" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const w = v.g.D_800F1A04();
    w.* = switch (ctx.range(u8, 0, 4)) {
        0 => 0,
        1 => 0x0001_0000,
        2 => 0x8000_0000,
        3 => 0xFFFF_0000,
        else => ctx.int(u32),
    };

    var a0: ?*v.vs_action_t = null;
    var a1: ?*v._hitEntity_t = null;
    var a2: ?*v._hitEntity_t = null;
    if (!ctx.chance(2)) a0 = ctx.alloc(v.vs_action_t);
    if (!ctx.chance(2)) a1 = @ptrCast(ctx.alloc(v.vs_action_t));
    if (!ctx.chance(2)) a2 = @ptrCast(ctx.alloc(v.vs_action_t));
    return .{ a0, a1, a2, ctx.int(c_int), ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    _ = args;
    const w = v.g.D_800F1A04().*;
    if (w == 0) return 0;
    if (w & 0xFFFF == 0) return 1;
    return 2;
}
