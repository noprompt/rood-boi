//! Battle display setup: calls the battle draw-state routines in order and sets D_800F1968
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8006C39C (src/BATTLE/BATTLE.PRG/146C.c)
/// Resets the battle display state and marks D_800F1968 as set.
pub fn func_8006C39C() callconv(.c) void {
    c.func_8007B10C(13, 4, -4, -4, 0);
    c.vs_main_setClutState(0);
    c.func_8006C2A0();
    c.func_8008B4BC(1);
    c.func_8008D594(1);
    _ = c.func_8008B4C8(@as(u8, 0));
    c.func_8008E480(1);
    c.func_80095B70(1);

    v.g.D_800F1968().* = 1;
}
