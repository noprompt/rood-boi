//! Reports whether the battle flag from func_800A0BE0 is set and func_800CB45C returns 0 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007424C (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when func_800A0BE0(0) has bit 27 set and func_800CB45C() returns 0, else 0.
pub fn func_8007424C() callconv(.c) c_int {
    var ret: c_int = 0;
    if ((c.func_800A0BE0(0) & 0x08000000) != 0) {
        ret = @intFromBool(c.func_800CB45C() == 0);
    }
    return ret;
}
