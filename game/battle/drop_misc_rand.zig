//! Drops the miscellaneous item from a random-drop table entry into the loot record
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _dropMiscRand (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores the entry's misc item in the loot's third misc slot, and sets it to one count with difficulty flags 3 if the roll succeeds.
pub fn dropMiscRand(looted: ?*v.vs_battle_loot, base: ?*v.vs_battle_uiMiscRand) callconv(.c) c_int {
    const loot = looted.?;
    const entry = base.?;

    loot.misc[2].id = entry.id;

    if (loot.misc[2].id != 0) {
        if (c.vs_main_getRand(0xFF) < @as(c_int, entry.dropRate)) {
            loot.misc[2].count = 1;
            loot.misc[2].difficultyFlags = 3;
            return 1;
        }
    }

    return 0;
}
