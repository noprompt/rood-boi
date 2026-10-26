//! Consumes the pending flag at D_800F18F8 when it matches the argument
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007E1C0 (src/BATTLE/BATTLE.PRG/146C.c)
/// Clears D_800F18F8 and returns 1 when it equals arg0; otherwise calls vs_main_nop9(0x67, 0) and returns 0.
pub fn func_8007E1C0(arg0: c_int) callconv(.c) c_int {
    const flag = v.g.D_800F18F8();
    if (@as(c_int, flag.*) == arg0) {
        flag.* = 0;
        return 1;
    }
    c.vs_main_nop9(0x67, 0);
    return 0;
}
