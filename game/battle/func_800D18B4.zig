//! Eased interpolation between two values, by a cosine curve of arg3 / arg2
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const c = @import("c_5BF94");

/// orig: func_800D18B4 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Interpolates from arg0 to arg1 by 4096 - cos of the angle arg3 / arg2 (scaled to 4096 per turn).
pub fn func_800D18B4(arg0: c_int, arg1: c_int, arg2: c_int, arg3: c_int) callconv(.c) c_int {
    const half: c_int = @divTrunc(arg3 *% 4096, 2);
    const angle: c_int = @divTrunc(half, arg2);
    return c.vs_battle_lerp(arg0, arg1, 4096 -% c.rcos(angle));
}
