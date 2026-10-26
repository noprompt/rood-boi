//! zig_diff spec: _updateWeaponKillStreak -> update_weapon_kill_streak.updateWeaponKillStreak (146C.c).
//! Inputs: the character's actor with a valid stats block in the arena, a
//! D_800F19CC block whose actionIndex sits at, below and above the 40 bound
//! (and at 0xFFFF), a blade category that matches the kill streak's category
//! about half the time (otherwise it differs, sometimes by one), and a kill
//! streak at 0, 98-101 or 255 so it hits the 100 cap. The C calls nothing, so
//! there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").updateWeaponKillStreak));

pub const classes = [_][:0]const u8{ "early-return", "category-changes", "streak-counts", "streak-capped" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    const d = ctx.alloc(v.D_800F19CC_t);
    const score = v.g.scoreData();

    v.g.vs_battle_characterState().* = actor;
    v.g.D_800F19CC().* = d;
    psx.put(&actor.stats, stats);

    d.unk8.actionIndex = ctx.pick(u16, &.{ 39, 40, 41, 0, 0xFFFF });

    const cat = ctx.int(u8);
    score.weaponKillStreakBladeCategory = cat;
    stats.weapon.blade.category = if (ctx.chance(2)) cat else cat +% ctx.range(u8, 1, 255);

    score.weaponKillStreak = ctx.pick(u8, &.{ 0, 98, 99, 100, 101, 255 });

    return .{ctx.int(c_int)};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F19CC().*.?;
    if (d.unk8.actionIndex >= 40) return 0;
    const score = v.g.scoreData();
    const actor = v.g.vs_battle_characterState().*.?;
    const stats = psx.get(actor.stats) orelse return 1;
    if (score.weaponKillStreakBladeCategory != stats.weapon.blade.category) return 1;
    return if (score.weaponKillStreak < 100) 2 else 3;
}
