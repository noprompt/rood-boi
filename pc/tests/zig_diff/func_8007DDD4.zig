//! zig_diff spec: func_8007DDD4 -> func_8007DDD4.func_8007DDD4 (146C.c).
//! Inputs: a P_CODE in the arena with random bytes (the source of the copy),
//! or the global D_800F1A78 itself as the source (the self-copy alias). The C
//! has no branches; the checks are that the whole four-byte struct is copied
//! into the global, that the source is left unchanged, and that the copy is
//! exact for every byte value (including the sign bit of each byte).
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007DDD4));

pub const classes = [_][:0]const u8{ "arena-source", "global-source" };

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(4)) return .{v.g.D_800F1A78()};
    const src = ctx.alloc(v.P_CODE);
    src.* = .{
        .r0 = ctx.pick(u8, &.{ 0, 0x7F, 0x80, 0xFF }),
        .g0 = ctx.pick(u8, &.{ 0, 0x7F, 0x80, 0xFF }),
        .b0 = ctx.pick(u8, &.{ 0, 0x7F, 0x80, 0xFF }),
        .code = ctx.pick(u8, &.{ 0, 0x7F, 0x80, 0xFF }),
    };
    return .{src};
}

pub fn classify(args: Args) usize {
    const p = args[0].?;
    return if (@intFromPtr(p) == @intFromPtr(v.g.D_800F1A78())) 1 else 0;
}
