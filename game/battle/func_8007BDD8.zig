//! Sets the first-person view flag from arg0 (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007BDD8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_8008C40C, then stores the low bit of ~arg0 as the first-person view flag and returns it.
pub fn func_8007BDD8(arg0: c_int) callconv(.c) c_int {
    c.func_8008C40C();
    const value: c_int = (~arg0) & 1;
    v.g._firstPersonViewEnabled().* = value;
    return value;
}
