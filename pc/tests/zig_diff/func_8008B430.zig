//! zig_diff spec: func_8008B430 -> func_8008B430.func_8008B430 (146C.c).
//! Inputs: an arg0 object in the arena whose leading bytes are zero up to a
//! chosen field, so the && chain stops at unk0, unk1, unk2 or runs to the end.
//! The other bytes are random, with the high bit set half the time for the
//! u8 to i8 narrowing. arg1 covers zero, both signs, and the i16 truncation
//! edges. The C makes no calls, so there are no stubs. The globals keep their
//! random fill and are compared as state.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B430));

pub const classes = [_][:0]const u8{
    "unk0-nonzero",
    "unk1-nonzero",
    "unk2-nonzero",
    "all-zero-arg1-nonzero",
    "all-zero-arg1-zero",
};

fn nz(ctx: *zd.Ctx) u8 {
    const x = ctx.int(u8);
    return if (x == 0) 0x80 else x;
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.D_800F4538_unk58_2);
    // z = 0: unk0 nonzero; 1: unk0 zero, unk1 nonzero; 2: unk0, unk1 zero,
    // unk2 nonzero; 3: all three zero.
    const z = ctx.range(u8, 0, 3);
    obj.unk0 = if (z == 0) nz(ctx) else 0;
    obj.unk1 = if (z == 1) nz(ctx) else if (z == 0) ctx.int(u8) else 0;
    obj.unk2 = if (z == 2) nz(ctx) else if (z == 3) 0 else ctx.int(u8);

    var arg1 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7fff, -0x8000, 0x8000, 0x10000, 0x7fffffff, -0x80000000 });
    if (z == 3 and ctx.chance(2)) arg1 = 0;
    return .{ obj, arg1 };
}

pub fn classify(args: Args) usize {
    const o = args[0].?;
    if (o.unk0 != 0) return 0;
    if (o.unk1 != 0) return 1;
    if (o.unk2 != 0) return 2;
    return if (args[1] == 0) 4 else 3;
}
