//! zig_diff spec: _enemyDefeated -> enemy_defeated.enemyDefeated (146C.c).
//! Inputs: the 16-entry vs_battle_actors table, each entry its own arena actor,
//! with actorId anywhere in 0..15 (so the C must index, not use slot 0). The
//! chosen enemy's unk27 is 0x80 about a quarter of the time, and its defeated
//! flag is zero or set. arg0 and arg2 come from zero, +-1 and the extremes, so
//! both tests of `arg2 != 0` and `arg0 == 0` see the sign bit set and clear.
//! The callees are recording stubs; _dropLoot writes enemy->defeated, which the
//! final store then overwrites.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").enemyDefeated));

pub const classes = [_][:0]const u8{ "dead-unk27", "already-defeated", "kill", "arg0-set", "no-kill" };

pub const stubs = struct {
    pub fn _dropLoot(ctx: *zd.Ctx, enemy: anytype) void {
        const a: *v.vs_battle_actor = @ptrCast(@alignCast(enemy));
        a.defeated = ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const tbl = v.g.vs_battle_actors();
    for (0..16) |i| tbl[i] = ctx.alloc(v.vs_battle_actor);
    const actorId = ctx.range(c_int, 0, 15);
    const enemy = tbl[@as(usize, @intCast(actorId))].?;
    enemy.unk27 = if (ctx.chance(4)) 0x80 else ctx.pick(u8, &.{ 0, 1, 0x7F, 0x81, 0xFF });
    enemy.defeated = if (ctx.chance(3)) ctx.pick(u8, &.{ 1, 0x80, 0xFF }) else 0;
    const arg0 = ctx.pick(c_int, &.{ 0, 0, 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000 });
    const arg2 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000 });
    return .{ arg0, actorId, arg2 };
}

pub fn classify(args: Args) usize {
    const enemy = v.g.vs_battle_actors()[@as(usize, @intCast(args[1]))].?;
    if (enemy.unk27 == 0x80) return 0;
    if (enemy.defeated != 0) return 1;
    if (args[2] != 0 and args[0] == 0) return 2;
    if (args[0] != 0) return 3;
    return 4;
}
