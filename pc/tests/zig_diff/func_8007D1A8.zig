//! zig_diff spec: func_8007D1A8 -> func_8007D1A8.func_8007D1A8 (146C.c).
//! Inputs: an index into vs_battle_actors covering all 16 slots, a flag
//! (zero, 1, -1, and the sign-bit extremes), and an actor or NULL in that
//! slot. The removal and insertion results are zero or nonzero (of either
//! sign) through spec variables set by prepare, so classify can name the
//! branch before the run. The callees' void calls draw from ctx.value and
//! may clear table slots 0 and 15; the C never reads the table again.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007D1A8));

pub const classes = [_][:0]const u8{ "no-actor", "remove-zero", "remove-hit", "insert-zero", "insert-hit" };

/// Results the stubs return this iteration (set by prepare, the same in both runs).
var remove_ret: c_int = 0;
var insert_ret: c_int = 0;

pub const stubs = struct {
    pub fn _removeActor(ctx: *zd.Ctx, p: anytype) c_int {
        _ = p;
        // The real call may unlink a slot; the C does not read the table after the call.
        if (ctx.value(u8) < 64) v.g.vs_battle_actors()[15] = null;
        return remove_ret;
    }

    pub fn _insertActor(ctx: *zd.Ctx, p: anytype) c_int {
        _ = p;
        if (ctx.value(u8) < 64) v.g.vs_battle_actors()[0] = null;
        return insert_ret;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const idx = ctx.range(c_int, 0, 15);
    const flag = ctx.pick(c_int, &.{ 0, 1, -1, 0x7fff_ffff, -0x8000_0000 });
    const actor: ?*v.vs_battle_actor = if (ctx.chance(4)) null else ctx.alloc(v.vs_battle_actor);
    v.g.vs_battle_actors()[@as(usize, @intCast(idx))] = actor;
    remove_ret = if (ctx.chance(2)) 0 else ctx.edge(c_int, &.{ -1, 1, 0x4000_0000, -0x8000_0000 });
    insert_ret = if (ctx.chance(2)) 0 else ctx.edge(c_int, &.{ -1, 1, 0x4000_0000, -0x8000_0000 });
    return .{ idx, flag };
}

pub fn classify(args: Args) usize {
    if (v.g.vs_battle_actors()[@as(usize, @intCast(args[0]))] == null) return 0;
    if (args[1] != 0) return if (remove_ret == 0) 1 else 2;
    return if (insert_ret == 0) 3 else 4;
}
