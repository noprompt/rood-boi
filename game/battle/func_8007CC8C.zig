//! Forwards to func_8009CFA0 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007CC8C (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_8009CFA0 and discards its result.
pub fn func_8007CC8C() callconv(.c) void {
    _ = c.func_8009CFA0();
}
