//! Hit prerequisite that always passes: the action can always hit
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: _hitPrerequisiteAlways0 (src/BATTLE/BATTLE.PRG/146C.c)
/// Hit prerequisite check that always succeeds, whatever the action and its argument.
pub fn hitPrerequisiteAlways0(_: ?*v.vs_action_t, _: [*c]u8) callconv(.c) c_int {
    return 1;
}
