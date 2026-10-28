//! Hit prerequisite that never holds (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: _hitPrerequisiteNever1 (src/BATTLE/BATTLE.PRG/146C.c)
/// Hit prerequisite that always fails: returns 0 whatever the action and target.
pub fn hitPrerequisiteNever1(_: ?*v.vs_action_t, _: [*c]u8) callconv(.c) c_int {
    return 0;
}
