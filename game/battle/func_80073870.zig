//! Runs two battle steps in order (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_80073870 (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_800BEC30 (its result is discarded), then func_80073718.
pub fn func_80073870() callconv(.c) void {
    _ = c.func_800BEC30();
    c.func_80073718();
}
