//! zig_diff spec: vs_battle_parseTim -> parse_tim.parseTim (146C.c).
//! Inputs: a 64-byte word buffer in the arena whose word 1 is the TIM mode
//! and word 2 the word the C reads for the CLUT skip, plus a TIM_IMAGE in the
//! arena with random fields. The mode's bit 3 is set or clear (the sign bit
//! both ways, and the mode edges 0, 8, 0x80000000, 0x80000008), and the count
//! word covers zero, small values and values with the sign bit set, which the
//! unsigned shift must read as unsigned. The C has no calls and no globals.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").parseTim));

pub const classes = [_][:0]const u8{ "no-clut", "clut", "clut-count-sign" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const words: [*]c_uint = @ptrCast(@alignCast(ctx.allocBytes(64, 16)));
    const tim = ctx.alloc(v.TIM_IMAGE);

    var mode: u32 = ctx.int(u32);
    if (ctx.chance(4)) {
        mode = ctx.edge(u32, &.{ 0, 8, 0x8000_0000, 0x8000_0008 });
    } else if (ctx.chance(2)) {
        mode |= 8;
    } else {
        mode &= ~@as(u32, 8);
    }
    const count = ctx.pick(u32, &.{ 0, 1, 2, 3, 0x7FFF_FFFF, 0x8000_0000, 0xFFFF_FFFF });

    words[1] = mode;
    words[2] = count;
    return .{ words, tim };
}

pub fn classify(args: Args) usize {
    const mode: u32 = args[0][1];
    const count: u32 = args[0][2];
    if ((mode & 8) == 0) return 0;
    if ((count & 0x8000_0000) != 0) return 2;
    return 1;
}
