//! No-op placeholder function from the battle overlay's 146C unit (src/BATTLE/BATTLE.PRG/146C.c).

/// orig: _vsBattleNop2 (src/BATTLE/BATTLE.PRG/146C.c)
/// Does nothing; the argument is ignored.
pub fn vsBattleNop2(_: c_int) callconv(.c) void {}
