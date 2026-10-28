//! Quicken prerequisite check: an effect-prerequisite query for effect 11
//! (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyQuicken (src/BATTLE/BATTLE.PRG/146C.c)
/// Whether Quicken can be applied: true when the effect-11 prerequisite check fails to pass (returns 0).
pub fn hitPrerequisiteCanApplyQuicken(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    const r = c._hitPrerequisiteCanApplyEffect(11, arg1);
    return @as(c_int, @intFromBool(r == 0));
}
