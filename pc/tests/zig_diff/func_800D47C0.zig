//! zig_diff spec: func_800D47C0 -> func_800D47C0.func_800D47C0 (5BF94.c).
//! The C ignores its argument and returns 2, so the only input that matters is
//! whether the argument is NULL. Inputs: a NULL argument, or a valid object in
//! the arena with random contents (the C never reads it, so the bytes must not
//! change the result). Mutations change the returned value and make it depend
//! on the argument's nullness.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D47C0));

pub const classes = [_][:0]const u8{ "null-arg", "valid-arg" };

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(3)) return .{null};
    const obj = ctx.alloc(v.D_800F53B8_t);
    return .{obj};
}

pub fn classify(args: Args) usize {
    return if (args[0] == null) 0 else 1;
}
