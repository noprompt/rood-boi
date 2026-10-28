//! Prerequisite check that always passes for hit tables (src/BATTLE/BATTLE.PRG/146C.c).

/// orig: _hitPrerequisiteAlways2 (src/BATTLE/BATTLE.PRG/146C.c)
/// Hit prerequisite that always holds: returns 1 whatever the action and argument.
pub fn hitPrerequisiteAlways2(_: ?*@import("views_146C").vs_action_t, _: [*c]u8) callconv(.c) c_int {
    return 1;
}
