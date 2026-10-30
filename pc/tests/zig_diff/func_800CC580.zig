//! zig_diff spec: func_800CC580 -> func_800CC580.func_800CC580 (5BF94.c).
//! The C has no branch: it forms three words from arg1 (OR-ed with fixed
//! constants, plus 0x3F for the xy word) and calls vs_battle_addTile with
//! arg0 passed through. The inputs cover arg0 null or pointing at an arena
//! object, and arg1 negative or not, drawn from edge values (0, -1, 0x3F,
//! the signed and unsigned extremes) and random ints. The C never reads
//! arg0, so null is safe. The stub is the recording stub, so the call's
//! arguments are compared.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CC580));

pub const classes = [_][:0]const u8{
    "null-nonneg",
    "null-neg",
    "ptr-nonneg",
    "ptr-neg",
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const before: [*c]c_uint = if (ctx.chance(8)) null else ctx.alloc(c_uint);
    const arg1 = ctx.pick(c_int, &.{ 0, -1, 0x3F, 0x7FFF_FFFF, -0x8000_0000, 0x0100_0000, 0xC0 });
    return .{ before, arg1 };
}

pub fn classify(args: Args) usize {
    const is_null: usize = @intFromBool(args[0] == null);
    const neg: usize = @intFromBool(args[1] < 0);
    return is_null * 2 + neg;
}
