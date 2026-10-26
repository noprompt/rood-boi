//! Maps the battle screen transition step to its phase number (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007C398 (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the screen transition phase for the current step: steps 1-2 give 1, steps 3-7 give 2-6, others 0.
pub fn func_8007C398() callconv(.c) c_int {
    const step: c_uint = v.g.vs_battle_screenTransitionStep().*;
    return switch (step) {
        1, 2 => 1,
        3 => 2,
        4 => 3,
        5 => 4,
        6 => 5,
        7 => 6,
        0 => 0,
        else => 0,
    };
}
