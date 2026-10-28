//! Battle unit 146C: forwards its argument to func_8009CE9C (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const c = @import("c_146C");

/// orig: func_8007CC6C (src/BATTLE/BATTLE.PRG/146C.c)
/// Passes its argument on to func_8009CE9C and discards the result.
pub fn func_8007CC6C(arg0: c_int) callconv(.c) void {
    _ = c.func_8009CE9C(psx.conv(c_uint, arg0));
}
