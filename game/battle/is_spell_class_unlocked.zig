//! Whether any spell of a spell class is unlocked (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

/// orig: vs_battle_isSpellClassUnlocked (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns 1 when any action in spell class `spellClass` is unlocked, else 0.
pub fn isSpellClassUnlocked(spellClass: c_int) callconv(.c) c_int {
    var i: c_int = 0;
    // The C re-reads _spellClassCounts[spellClass] on every test; the class index is
    // not checked, so psx.at takes it as a signed index (no bounds check).
    while (i < @as(c_int, psx.at(v.g._spellClassCounts(), spellClass).*)) : (i +%= 1) {
        // _spellIds[spellClass] is a table pointer in the C; a null one dereferences null there too.
        const actionId: u8 = psx.at(psx.at(v.g._spellIds(), spellClass).*.?, i).*;
        if (psx.getBits(&v.g.actions()[actionId], "unlocked") != 0) {
            return 1;
        }
    }
    return 0;
}
