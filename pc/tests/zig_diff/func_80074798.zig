//! zig_diff spec: func_80074798 -> func_80074798.func_80074798 (146C.c).
//! Inputs: a func_8006EBF8_t in the arena with a random pad (an i16 edge or
//! any value, so (pad + 0x200) & 0xFFF hits 0 and every quarter of 0..4095),
//! its three control bytes at edge values (0, 127, 128, 255, so the char
//! increments and decrements wrap at both ends), and a 4-byte output buffer
//! in the arena with edge bytes. The C makes no calls.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80074798));

pub const classes = [_][:0]const u8{ "masked-zero", "case-0", "case-1", "case-2", "default" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.func_8006EBF8_t);
    obj.unk0.unk4.pad = ctx.pick(i16, &.{ -512, 3584, -4608, 511, 512, 1535, 1536, 2559, 2560, 3583, -1536, -1, 0, 32767, -32768 });
    for (&obj.unk0.unk0._bytes) |*b| b.* = ctx.pick(u8, &.{ 0, 127, 128, 255 });
    const out: [*c]u8 = @ptrCast(ctx.allocBytes(4, 1));
    for (0..4) |i| out[i] = ctx.pick(u8, &.{ 0, 127, 128, 255 });
    return .{ obj, out };
}

pub fn classify(args: Args) usize {
    const pad: i32 = args[0].?.unk0.unk4.pad;
    const vv = (pad + 0x200) & 0xFFF;
    if (vv == 0) return 0;
    return switch (vv >> 10) {
        0 => 1,
        1 => 2,
        2 => 3,
        else => 4,
    };
}
