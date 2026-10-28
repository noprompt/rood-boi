//! Enemy class of the battle actor whose slot is named by a byte (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: _getEnemyClass (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the enemy class of the battle actor in slot `arg0[0]`, read from its stats.
pub fn getEnemyClass(arg0: [*c]u8) callconv(.c) c_int {
    const actor = v.g.vs_battle_actors()[arg0[0]].?;
    const stats = psx.get(actor.stats).?;
    return @as(c_int, psx.getBits(stats, "enemyClass"));
}
