//! Hit prerequisite callback that always succeeds (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: _hitPrerequisiteAlways1 (src/BATTLE/BATTLE.PRG/146C.c)
/// Hit prerequisite that always holds: returns 1 whatever the action and target.
pub fn hitPrerequisiteAlways1(_: ?*v.vs_action_t, _: [*c]u8) callconv(.c) c_int {
    return 1;
}
