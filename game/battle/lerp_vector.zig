//! Linear interpolation of a three-axis vector between two short triples,
//! in 1/128 steps (src/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");

/// orig: vs_battle_lerpVector (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Writes `src` start/end pairs interpolated at `t`/128 into `vec`.
pub fn lerpVector(src: [*c]c_short, t: c_int, vec: ?*v.VECTOR) callconv(.c) void {
    const start0: c_int = src[0];
    const end0: c_int = src[1];
    const start1: c_int = src[2];
    const end1: c_int = src[3];
    const start2: c_int = src[4];
    const end2: c_int = src[5];

    const out = vec.?;
    out.vx = (((end0 -% start0) *% t) >> 7) +% start0;
    out.vy = (((end1 -% start1) *% t) >> 7) +% start1;
    out.vz = (((end2 -% start2) *% t) >> 7) +% start2;
}
