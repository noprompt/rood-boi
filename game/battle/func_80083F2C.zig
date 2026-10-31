//! Applies status set 0x15 to a hit entity (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80083F2C (src/BATTLE/BATTLE.PRG/146C.c)
/// Applies the applicable statuses 0x15 to the target entity and returns what that call returns.
pub fn func_80083F2C(_: ?*v.vs_action_t, _: ?*v._hitEntity_t, arg2: ?*v._hitEntity_t, _: c_int, _: c_int) callconv(.c) c_int {
    // The C has no return statement; the object tail-calls _setApplicableStatuses, so its result is returned.
    return c._setApplicableStatuses(0x15, @ptrCast(arg2));
}
