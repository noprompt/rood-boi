//! Gets a stack vector from func_800780A8 and steps it toward its target (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007820C (src/BATTLE/BATTLE.PRG/146C.c)
/// Gets a stack vector from func_800780A8 and, when `step` is nonzero, steps it toward its target.
pub fn func_8007820C(step: c_int) callconv(.c) void {
    var sp10: v.SVECTOR = undefined;
    c.func_800780A8(psx.cptr(c.SVECTOR, &sp10));
    if (step != 0) {
        _ = c._stepTowardTarget(psx.cptr(c.SVECTOR, &sp10), 1, 0x28);
    }
}
