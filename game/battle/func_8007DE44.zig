//! Battle unit 146C: stores a small value in D_800F1A44 (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007DE44 (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores arg0 in D_800F1A44 when it is below 0x800; otherwise leaves the global alone.
pub fn func_8007DE44(arg0: c_uint) callconv(.c) void {
    if (arg0 < 0x800) {
        v.g.D_800F1A44().* = arg0;
    }
}
