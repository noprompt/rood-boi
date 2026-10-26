//! zig_diff spec: func_800792E4 -> func_800792E4.func_800792E4 (146C.c).
//! Inputs: an index 0-15 into vs_battle_actors, with the entry null or an
//! arena actor whose stats block (always present) has a currentHP of 0, -1,
//! 1, the i16 extremes or random, and an unk26 of 0, 1, 0x80 or 0xFF. The
//! entry for the index is set by prepare. arg0 and arg2 are passed through
//! to _enemyDefeated and cover 0, +-1 and the int extremes. The stubs model
//! _enemyDefeated writing the actor's unk26 (zero or nonzero, so both
//! branches after it are taken), _removeActorAtIndex clearing its table
//! entry sometimes, and func_800BEC58 returning any c_short.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800792E4));

pub const classes = [_][:0]const u8{
    "null-actor",
    "alive",
    "dead-player",
    "dead-enemy-unk26-zero",
    "dead-enemy-unk26-set",
};

pub const stubs = struct {
    pub fn _enemyDefeated(ctx: *zd.Ctx, arg0: anytype, arg1: anytype, arg2: anytype) void {
        _ = arg0;
        _ = arg2;
        if (v.g.vs_battle_actors()[@intCast(arg1)]) |a| {
            a.unk26 = if (ctx.value(u1) == 1) 0 else ctx.value(u8) | 1;
        }
    }

    pub fn func_8009722C(ctx: *zd.Ctx) void {
        _ = ctx;
    }

    pub fn func_8009E5C4(ctx: *zd.Ctx, arg: anytype) void {
        _ = ctx;
        _ = arg;
    }

    pub fn func_800BEC58(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype, d: anytype) c_short {
        _ = a;
        _ = b;
        _ = c;
        _ = d;
        return ctx.value(c_short);
    }

    pub fn func_80073898(ctx: *zd.Ctx) void {
        _ = ctx;
    }

    pub fn _removeActorAtIndex(ctx: *zd.Ctx, idx: anytype, flag: anytype) c_int {
        _ = flag;
        if (ctx.value(u1) == 1) v.g.vs_battle_actors()[@intCast(idx)] = null;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const idx: c_int = ctx.range(c_int, 0, 15);
    const table = v.g.vs_battle_actors();
    const stats = ctx.alloc(v.vs_battle_actor2);
    const actor = ctx.alloc(v.vs_battle_actor);
    stats.currentHP = ctx.pick(i16, &.{ 0, 0, -1, 1, -32768, 32767 });
    psx.put(&actor.stats, stats);
    actor.unk26 = ctx.pick(u8, &.{ 0, 1, 0x80, 0xFF });
    table[@intCast(idx)] = if (ctx.chance(8)) null else actor;
    const a0 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000 });
    const a2 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000 });
    return .{ a0, idx, a2 };
}

pub fn classify(args: Args) usize {
    const idx: usize = @intCast(args[1]);
    const actor = v.g.vs_battle_actors()[idx] orelse return 0;
    const stats = psx.get(actor.stats).?;
    if (stats.currentHP != 0) return 1;
    if (args[1] == 0) return 2;
    return if (actor.unk26 == 0) 3 else 4;
}
