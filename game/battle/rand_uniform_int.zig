//! A random integer between two bounds (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).
const c = @import("c_5BF94");

/// orig: vs_battle_randUniformInt (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// low + rand() % (high - low) for the lower and higher of the two (half-open); `a` when they are equal.
pub fn randUniformInt(a: c_int, b: c_int) callconv(.c) c_int {
    if (a != b) {
        if (b < a) {
            const r = @rem(c.rand(), a -% b);
            return r +% b;
        }
        const r = @rem(c.rand(), b -% a);
        return r +% a;
    }
    return a;
}
