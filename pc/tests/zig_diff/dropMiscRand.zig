//! zig_diff spec: _dropMiscRand -> drop_misc_rand.dropMiscRand (146C.c).
//! Inputs: a random loot block and a base uiMiscRand in the arena. The id is
//! zero about a quarter of the time. dropRate is an edge (0, 1, 128, 254, 255).
//! The getRand stub returns `want`, which prepare sets to dropRate-1, dropRate
//! or dropRate+1, so the `<` sees equal sides often. One call in four it returns
//! any c_int instead (negative, zero, huge), which exercises the signed compare.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").dropMiscRand));

pub const classes = [_][:0]const u8{ "id-zero", "roll-below", "roll-not-below" };

/// The roll prepare chose for this iteration (the same in both runs).
var want: c_int = 0;

pub const stubs = struct {
    pub fn vs_main_getRand(ctx: *zd.Ctx, n: anytype) c_int {
        _ = n;
        if (ctx.value(u2) == 0) return ctx.value(c_int);
        return want;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const looted = ctx.alloc(v.vs_battle_loot);
    const base = ctx.alloc(v.vs_battle_uiMiscRand);
    base.id = if (ctx.chance(4)) 0 else ctx.int(u16);
    base.dropRate = ctx.pick(u8, &.{ 0, 1, 128, 254, 255 });
    const rate: c_int = base.dropRate;
    const offset: c_int = ctx.edge(i8, &.{ -1, 0, 0, 1 });
    want = rate + offset;
    if (ctx.chance(12)) want = ctx.edge(c_int, &.{ 0, 255, -1 });
    return .{ looted, base };
}

pub fn classify(args: Args) usize {
    const base = args[1].?;
    if (base.id == 0) return 0;
    return if (want < @as(c_int, base.dropRate)) 1 else 2;
}
