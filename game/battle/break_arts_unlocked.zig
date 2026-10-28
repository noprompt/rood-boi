//! Break arts unlock check: whether any art of the equipped weapon category is unlocked (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

/// orig: _breakArtsUnlocked (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns 1 if one of the four break arts of the character's equipped weapon category is unlocked, else 0.
pub fn breakArtsUnlocked() callconv(.c) c_int {
    var i: c_int = 0;
    while (i < 4) : (i +%= 1) {
        // The C does not bound the index: a category past 63 reads beyond vs_main_actions, as psx.at does.
        const category: c_int = v.g.vs_battle_characterState().*.?.equippedWeaponCategory;
        const index: c_int = 0xB8 +% (category -% 1) *% 4 +% i;
        if (psx.getBits(psx.at(v.g.actions(), index), "unlocked") != 0) {
            return 1;
        }
    }
    return 0;
}
