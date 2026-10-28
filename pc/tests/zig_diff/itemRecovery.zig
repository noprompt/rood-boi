//! zig_diff spec: _itemRecovery -> item_recovery.itemRecovery (146C.c).
//! Inputs: an action in the arena whose hitParams entry is picked by arg3
//! (mostly 0 and 1, and -5..6 so the index reads past the array but stays in
//! the struct), with statFactor 0, 1 or 31 or random, so the base is 0, 5 or
//! 155 and the sum with the random roll hits zero and wraps; arg4 zero,
//! negative, positive, both signs' extremes and random; arg1 and arg2 null or
//! allocated (the C never reads them). The roll is a recording stub returning
//! a random i16 through getRandSmoothed(0xB), so the sum goes negative about
//! half the time and overflows short when the roll is near 32767.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").itemRecovery));

pub const classes = [_][:0]const u8{ "arg4-zero", "arg4-negative", "arg4-positive", "index-outside" };

pub const stubs = struct {
    pub fn vs_main_getRandSmoothed(ctx: *zd.Ctx, arg: anytype) c_int {
        _ = arg;
        return @as(c_int, ctx.value(i16));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    // Room before the first object so that negative indices stay in the arena.
    _ = ctx.allocBytes(64, 16);
    const action = ctx.alloc(v.vs_action_t);
    const arg3: c_int = if (ctx.chance(2)) ctx.edge(c_int, &.{ 0, 1 }) else ctx.range(c_int, -5, 6);
    const hp: *align(1) v.vs_action_t_hitParams = psx.byteAt(v.vs_action_t_hitParams, action, 20 + 4 * @as(isize, arg3));
    psx.setBits(hp, "statFactor", ctx.pick(u5, &.{ 0, 1, 31 }));
    const arg4: c_int = ctx.pick(c_int, &.{ 0, 0, 1, -1, std.math.minInt(c_int), std.math.maxInt(c_int) });
    const other: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    return .{ action, null, other, arg3, arg4 };
}

pub fn classify(args: Args) usize {
    if (args[3] < 0 or args[3] > 1) return 3;
    if (args[4] == 0) return 0;
    return if (args[4] < 0) 1 else 2;
}
