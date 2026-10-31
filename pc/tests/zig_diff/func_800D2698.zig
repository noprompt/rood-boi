//! zig_diff spec: func_800D2698 -> func_800D2698.func_800D2698 (5BF94.c).
//! Inputs: the reset flag D_800F5600 zero or nonzero (1, 2, -1, -2, 1000),
//! and count from -1, 0, 1, 2, 3 (the loop's `i < count - 1` sees equal sides
//! at count 2) or any 0..200. The allocator stub hands out arena blocks of at
//! least two elements; a negative count asks for a huge block, so the stub
//! gives two elements, which is all the C touches for it. Globals D_800F55F0,
//! D_800F55F4, D_800F55F8 and D_800F55FC start as random bytes and the C
//! overwrites them.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D2698));

pub const classes = [_][:0]const u8{ "flag-set", "count-below-2", "count-2", "count-3-up" };

pub const stubs = struct {
    /// Never returns null: the C writes through the result at once.
    pub fn vs_main_allocHeapR(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        const elem = @sizeOf(v.func_800D2904_t);
        // A negative count asks for a huge block; the C only touches elements 0 and 1.
        const wanted: usize = if (size > 1 << 20) 2 * elem else @max(@as(usize, size), 2 * elem);
        return @ptrCast(ctx.allocBytes(wanted, 16));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const flag = v.g.D_800F5600();
    flag.* = if (ctx.chance(3)) 0 else ctx.edge(i32, &.{ 1, 2, -1, -2, 1000 });
    const count: c_int = if (ctx.chance(4))
        ctx.edge(c_int, &.{ -1, 0, 1, 2, 3 })
    else
        ctx.range(c_int, 0, 200);
    return .{count};
}

pub fn classify(args: Args) usize {
    if (v.g.D_800F5600().* != 0) return 0;
    const n = args[0];
    if (n < 2) return 1;
    if (n == 2) return 2;
    return 3;
}
