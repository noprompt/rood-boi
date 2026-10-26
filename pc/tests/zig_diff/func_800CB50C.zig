//! zig_diff spec: func_800CB50C -> func_800CB50C.func_800CB50C (5BF94.c).
//! Inputs: the text-box heap pointer D_800EB9D8 in three shapes: null (the
//! branch is skipped), a block in the arena (the dismiss, free and clear
//! run), and a random nonzero 32-bit address with its sign bit set or clear
//! (the nonzero test sees both signs). The callees are recording stubs: the
//! dismiss returns any int and does not touch the pointer, and the free only
//! records its argument. The C run and the port must leave the same bytes
//! in the global and the same call trace.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CB50C));

pub const classes = [_][:0]const u8{ "null", "arena", "raw" };

var kind: usize = 0;

pub fn prepare(ctx: *zd.Ctx) Args {
    const slot = v.g.nameWindowText();
    if (ctx.chance(3)) {
        kind = 0;
        slot.* = null;
    } else if (ctx.chance(2)) {
        kind = 1;
        const p: [*]i32 = @ptrCast(@alignCast(ctx.allocBytes(64, 4)));
        slot.* = p;
    } else {
        kind = 2;
        // Nonzero and 4-aligned; bit 31 random, so the test sees both signs.
        const raw: usize = (ctx.int(u32) & ~@as(u32, 3)) | 4;
        slot.* = @ptrFromInt(raw);
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return kind;
}
