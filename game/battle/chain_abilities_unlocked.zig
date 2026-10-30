//! Chain and defense ability unlock check (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");

/// orig: vs_battle_chainAbilitiesUnlocked (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Reports whether any of the 14 chain abilities (defense 0) or defense abilities is unlocked.
pub fn chainAbilitiesUnlocked(defense: c_int) callconv(.c) c_int {
    const actions = v.g.actions();
    const offsets: [*]u8 = if (defense == 0)
        v.g.vs_battle_chainAbilityOffsets()
    else
        v.g.vs_battle_defenseAbilityOffsets();

    // i runs 0..13 by the loop bound, so the index is in range and the increment cannot overflow.
    var i: c_int = 0;
    while (i < 14) : (i +%= 1) {
        // Offsets are u8, so the index is always below the 256 actions.
        const index = offsets[@intCast(i)];
        if (psx.getBits(&actions[index], "unlocked") != 0) return 1;
    }
    return 0;
}
