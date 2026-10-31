//! Accessor for the battle ability block D_800F4E98 (src/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");

/// orig: func_800CB66C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns the address of the ability block D_800F4E98.
pub fn func_800CB66C() callconv(.c) ?*v.D_800F18EC_t {
    return v.g.D_800F4E98();
}
