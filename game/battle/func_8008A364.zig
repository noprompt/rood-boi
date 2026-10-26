//! Removes the battle actors in slots 2 through 15 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8008A364 (src/BATTLE/BATTLE.PRG/146C.c)
/// Removes the actors in slots 2 to 15 with `_removeActorAtIndex(i, 0)`.
pub fn func_8008A364() callconv(.c) void {
    var i: c_int = 2;
    while (i < 16) : (i +%= 1) {
        _ = c._removeActorAtIndex(@as(c.u_int, @bitCast(i)), 0);
    }
}
