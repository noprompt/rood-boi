//! Battle unit 146C: removes the actor at an index (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const c = @import("c_146C");

/// orig: func_8007D340 (src/BATTLE/BATTLE.PRG/146C.c)
/// Removes the actor at index `arg0`, passing the C's extra 0 argument.
pub fn func_8007D340(arg0: c_int) callconv(.c) void {
    _ = c._removeActorAtIndex(psx.conv(c_uint, arg0), 0);
}
