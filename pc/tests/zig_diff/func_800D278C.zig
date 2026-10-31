//! zig_diff spec: func_800D278C -> func_800D278C.func_800D278C (5BF94.c).
//! Inputs: the decrement counter D_800F5600 (mostly 1, which takes the release
//! path; otherwise 0, 2, -1, 1000 and INT_MAX, which only decrement) and the
//! heap pointer D_800F55FC (null or a fresh arena block). The release path
//! frees the block only when it is non-null and then clears both globals.
//! vs_main_freeHeapR is a void recording stub: the C never reads anything it
//! could change (the pointer is only passed to it), so it needs no effect.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D278C));

pub const classes = [_][:0]const u8{ "release-null", "release-live", "decrement" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const heap = v.g.D_800F55FC();
    const count = v.g.D_800F5600();
    // INT_MIN is left out: decrementing it is undefined behaviour in the C.
    count.* = if (ctx.chance(2)) 1 else ctx.pick(i32, &.{ 0, 2, -1, 1000, std.math.maxInt(i32) });
    if (ctx.chance(2)) {
        heap.* = null;
    } else {
        heap.* = ctx.alloc(v.func_800D2904_t);
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if (v.g.D_800F5600().* != 1) return 2;
    return if (v.g.D_800F55FC().* == null) 0 else 1;
}
