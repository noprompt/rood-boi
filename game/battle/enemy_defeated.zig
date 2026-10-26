//! Marks an enemy defeated, counting its kill once, then drops its loot (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _enemyDefeated (src/BATTLE/BATTLE.PRG/146C.c)
/// Marks actor `actorId` defeated; a player kill (arg2 set, arg0 0) counts it and the weapon streak, then it drops its loot.
pub fn enemyDefeated(arg0: c_int, actorId: c_int, arg2: c_int) callconv(.c) void {
    const enemy = psx.at(v.g.vs_battle_actors(), actorId).*.?;

    if (enemy.unk27 == 0x80 or enemy.defeated != 0) {
        return;
    }

    if (arg2 != 0 and arg0 == 0) {
        c._updateEnemyKills(@ptrCast(enemy));
        c._updateWeaponKillStreak(0);
    }

    c._dropLoot(@ptrCast(enemy));

    enemy.defeated = 1;
}
