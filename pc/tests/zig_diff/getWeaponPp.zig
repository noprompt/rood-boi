//! zig_diff spec: _getWeaponPp -> get_weapon_pp.getWeaponPp (146C.c).
//! Inputs: sixteen battle actors in the vs_battle_actors table, each with its
//! own stats block and a random currentPp (edges 0, 1, 0x7FFF, 0x8000, 0xFFFF
//! half the time), a D_800F19CC block whose unk0 takes the low-16-bit edges
//! (0, 1, 0xFFFF, 0x10000 and so on), and a hit entity whose targetActor is
//! 0-15 (the table's room). A second hit entity is valid too, so a mutant that
//! reads arg2 still runs. The C has no calls and no branches; the result is a
//! short, so only the sum modulo 2^16 is observable. The three classes split
//! that sum: negative, in the positive short range, and wrapping past 32767.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getWeaponPp));

pub const classes = [_][:0]const u8{ "sum-negative", "sum-in-range", "sum-over-short" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const actors = v.g.vs_battle_actors();
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        const stats = ctx.alloc(v.vs_battle_actor2);
        psx.put(&actor.stats, stats);
        stats.weapon.currentPp = ctx.pick(u16, &.{ 0, 1, 0x7FFF, 0x8000, 0xFFFF });
        actors[i] = actor;
    }

    const work = ctx.alloc(v.D_800F19CC_t);
    work.unk0 = ctx.pick(u32, &.{ 0, 1, 0xFFFF, 0x10000, 0x10001, 0x8000, 0x7FFF_FFFF, 0xFFFF_FFFF });
    v.g.D_800F19CC().* = work;

    const hit = ctx.alloc(v._hitEntity_t);
    hit.unk0.targetActor = ctx.range(u8, 0, 15);
    const other = ctx.alloc(v._hitEntity_t);
    other.unk0.targetActor = ctx.range(u8, 0, 15);

    return .{
        if (ctx.chance(4)) null else ctx.alloc(v.vs_action_t),
        hit,
        other,
        ctx.int(c_int),
        ctx.int(c_int),
    };
}

pub fn classify(args: Args) usize {
    const hit = args[1].?;
    const actor = v.g.vs_battle_actors()[hit.unk0.targetActor].?;
    const stats = psx.get(actor.stats).?;
    const unk0 = v.g.D_800F19CC().*.?.unk0;
    const sum: i32 = @as(i32, stats.weapon.currentPp) + (@as(i32, @as(u16, @truncate(unk0))) - 1);
    if (sum < 0) return 0;
    if (sum <= 32767) return 1;
    return 2;
}
