//! An unused attack prerequisite (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: _hitPrerequisiteUnused0 (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// An unused attack prerequisite (index 37 of _attackPrerequisiteFunctions): returns no value.
pub fn hitPrerequisiteUnused0(_: ?*v.vs_action_t, _: [*c]u8) callconv(.c) c_int {
    // The C returns no value; its object leaves the caller's %eax (the 64-bit _canPerformAttack's table index,
    // the 32-bit one's function address): uninitialised in the original, 0 here (PORTING.md §11.4).
    return 0;
}
