//! Battle hit-prerequisite checks (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: _hitPrerequisiteNever3 (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Hit prerequisite that never allows the hit: always returns 0.
pub fn hitPrerequisiteNever3(_: ?*v.vs_action_t, _: [*c]u8) callconv(.c) c_int {
    return 0;
}
