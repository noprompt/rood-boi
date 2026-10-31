//! Battle unit 5BF94: runs three battle steps in turn (src/BATTLE/BATTLE.PRG/5BF94.c).
const c = @import("c_5BF94");

/// orig: func_800CE64C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Runs the battle steps func_800CE67C, func_800D7814 and func_800D268C, in that order.
pub fn func_800CE64C() callconv(.c) void {
    c.func_800CE67C();
    c.func_800D7814();
    c.func_800D268C();
}
