//! Stat calculator placeholder that does nothing (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: _statCalculatorNop (src/BATTLE/BATTLE.PRG/146C.c)
/// Does nothing: the stat calculator slot is left empty.
pub fn statCalculatorNop(_: ?*v.vs_action_t, _: ?*v._hitEntity_t, _: ?*v._hitEntity_t, _: c_int, _: c_int) callconv(.c) void {}
