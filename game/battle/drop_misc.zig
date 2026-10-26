//! Copies the two miscellaneous loot slots from the battle UI table into the loot record (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: _dropMisc (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies the first two misc drops into `looted`, marking each present one as dropped; returns 1 if any was.
pub fn dropMisc(looted: ?*v.vs_battle_loot, base: ?*v.vs_battle_uiMisc) callconv(.c) c_int {
    const loot = looted.?;
    const units: [*]v.vs_battle_uiMisc = @ptrCast(base.?);
    var ret: c_int = 0;

    var i: usize = 0;
    while (i < 2) : (i += 1) {
        const dst = &loot.misc[i];
        dst.id = units[i].id;

        if (dst.id != 0) {
            dst.count = units[i].count;
            dst.difficultyFlags = 3;
            ret = 1;
        }
    }

    return ret;
}
