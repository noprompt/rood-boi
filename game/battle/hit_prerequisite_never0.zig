//! Hit-prerequisite check that always passes (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: _hitPrerequisiteNever0 (src/BATTLE/BATTLE.PRG/146C.c)
/// Hit prerequisite that is never met: always returns 0.
pub fn hitPrerequisiteNever0(_: ?*v.vs_action_t, _: [*c]u8) callconv(.c) c_int {
    return 0;
}
