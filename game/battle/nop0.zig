//! No-op battle callback that accepts an actor and does nothing (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: vs_battle_nop0 (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Does nothing: a placeholder callback that takes a battle actor and returns.
pub fn nop0(_: ?*v.vs_battle_actor2) callconv(.c) void {}
