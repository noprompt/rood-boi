//! Sets bit 2 of each of the 16 slot flags that lack it (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8006C250 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets flag bit 4 on each of the 16 slots whose flags lack it.
pub fn func_8006C250() callconv(.c) void {
    var i: c_int = 0;
    while (i < 16) : (i +%= 1) {
        const temp_v0: c_uint = c.func_800A0BE0(i);
        if ((temp_v0 & 4) == 0) {
            c.func_800A087C(i, @bitCast(temp_v0 | 4));
        }
    }
}
