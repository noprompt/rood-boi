//! zig_diff spec: vs_battle_initInformationTextBox -> init_information_text_box.initInformationTextBox (5BF94.c).
//! Inputs: any c_uint header, drawn from the edges of the shift (0, 1, 0xFF, 0x100,
//! 0xFFFFFF, 0x1000000, bit 31 set, all ones) and random values. The shifted value
//! wraps out of the top byte, and it reaches the int parameter negative when bit 23
//! of header is set. vs_battle_initTextBox is a void recording stub with no results
//! the C reads back, so the default stub is the model.
const std = @import("std");
const zd = @import("zdiff");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").initInformationTextBox));

pub const classes = [_][:0]const u8{ "zero", "high-bit", "other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const header = ctx.pick(c_uint, &.{
        0,
        1,
        0xFF,
        0x100,
        0x00FF_FFFF,
        0x0100_0000,
        0x0080_0000,
        0x7FFF_FFFF,
        0x8000_0000,
        0xFFFF_FFFF,
    });
    return .{header};
}

pub fn classify(args: Args) usize {
    const header = args[0];
    if (header == 0) return 0;
    if (header & 0x8000_0000 != 0) return 1;
    return 2;
}
