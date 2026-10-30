//! Battle setup step: resets the CLUT state and the helper state, then clears D_800F1968 (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007B470 (src/BATTLE/BATTLE.PRG/146C.c)
/// Resets the CLUT state and the battle helper state, then clears D_800F1968.
pub fn func_8007B470() callconv(.c) void {
    c.vs_main_setClutState(1);
    c.func_8007B1B8(8, 4, 0, 0, 0);
    c.func_8006C250();
    c.func_8008B4BC(0);
    c.func_8008E480(0);
    v.g.D_800F1968().* = 0;
}
