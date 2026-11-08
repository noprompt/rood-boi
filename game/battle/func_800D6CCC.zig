//! Clears eight words (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).

/// orig: func_800D6CCC (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// words[0..8] = 0.
pub fn func_800D6CCC(words: [*c]c_int) callconv(.c) void {
    words[0] = 0;
    words[1] = 0;
    words[2] = 0;
    words[3] = 0;
    words[4] = 0;
    words[5] = 0;
    words[6] = 0;
    words[7] = 0;
}
