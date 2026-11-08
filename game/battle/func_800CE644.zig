//! An empty effect-loader hook (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).
/// orig: func_800CE644 (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// Does nothing. The C is `int f(int) { }` and falls off its end, so its result is the register's leftover
/// (not reproducible); the port returns 0.
pub fn func_800CE644(arg0: c_int) callconv(.c) c_int {
    _ = arg0;
    return 0;
}
