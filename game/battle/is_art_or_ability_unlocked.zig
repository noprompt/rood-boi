//! Whether the equipped weapon's next art or the next battle ability is unlocked (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: _isArtOrAbilityUnlocked (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the art unlock in bit 16 and the battle ability unlock in bit 0.
pub fn isArtOrAbilityUnlocked() callconv(.c) c_int {
    var unlockBattleAbility: c_int = 0;
    const character = v.g.vs_battle_characterState().*.?;
    // equippedWeaponCategory is a u8: % 10 gives 0..9, a valid index of the 10-entry tables.
    const category: c_int = @rem(@as(c_int, character.equippedWeaponCategory), 10);
    const artsStatus = v.g.vs_main_artsStatus();
    const artsLearned: c_uint = @as(c_uint, artsStatus.artsLearned[@intCast(category)]);

    var unlockArt: c_int = 0;
    if (artsLearned < 4) {
        // artsLearned < 4 here, so the row index is in range of the [4] entries.
        const row = v.g.vs_main_artsPointsRequirements()[@intCast(category)];
        unlockArt = @intFromBool(@as(c_int, artsStatus.kills.weaponCategories[@intCast(category)]) >= @as(c_int, row[@intCast(artsLearned)]));
    }
    if (unlockArt == 0) {
        const unlocked: u16 = artsStatus.kills.battleAbilitiesUnlocked;
        if (unlocked < 22) {
            if (@as(c_int, artsStatus.kills.total) >= @as(c_int, v.g.vs_main_battleAbilitiesPointsRequirements()[unlocked])) {
                unlockBattleAbility = 1;
            }
        }
    }
    // unlockArt is 0 or 1, so the shift cannot overflow.
    return (unlockArt << 16) | unlockBattleAbility;
}
