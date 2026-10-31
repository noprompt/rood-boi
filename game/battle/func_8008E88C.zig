//! Clears the battle's CD queue, background and sound pointers and sets the
//! defaults for the 146C state (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008E88C (src/BATTLE/BATTLE.PRG/146C.c)
/// Resets the battle's queued CD slots, background layout and table pointers, then runs func_8008E938.
pub fn func_8008E88C() callconv(.c) void {
    v.g.D_800F1DAC().* = null;
    v.g.D_800F1DB0().* = null;
    v.g.D_800F1DCC().* = null;
    v.g.D_800F1DD0().* = null;
    v.g.D_800F1DD4().* = null;
    v.g.D_800F1DC9().* = 0;
    v.g.D_800F1DBC().* = -2;
    v.g.D_800F1DCA().* = 0;
    v.g.D_800F1DCB().* = 1;
    c.func_8008E938();
}
