//! Lerps a pair of 16-bit endpoint pairs by t into two ints (src/BATTLE/BATTLE.PRG/5BF94.c).
/// orig: vs_battle_lerp2DVector (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Writes vec[0] and vec[1]: each is start + ((end - start) * t >> 7), from the pairs in src.
pub fn lerp2DVector(src: [*c]c_short, t: c_int, vec: [*c]c_int) callconv(.c) void {
    const start0: c_int = src[0];
    const end0: c_int = src[1];
    const start1: c_int = src[2];
    const end1: c_int = src[3];

    vec[0] = (((end0 -% start0) *% t) >> 7) +% start0;
    vec[1] = (((end1 -% start1) *% t) >> 7) +% start1;
}
