//! Hit-prerequisite callback for actions that never hit (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: _hitPrerequisiteNever2 (src/BATTLE/BATTLE.PRG/146C.c)
/// Hit prerequisite that always fails: returns 0 and touches no state.
pub fn hitPrerequisiteNever2(_: ?*v.vs_action_t, _: [*c]u8) callconv(.c) c_int {
    return 0;
}
