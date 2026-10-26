//! Clears the battle CLUT state and the overlay's flag at D_800F1968 (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8006C40C (src/BATTLE/BATTLE.PRG/146C.c)
/// Resets the battle CLUT state and the battle overlay's flag at D_800F1968.
pub fn func_8006C40C() callconv(.c) void {
    c.vs_main_setClutState(1);
    c.func_8007B1B8(8, 4, 0, 0, 0);
    c.func_8006C250();
    c.func_8008B4BC(0);
    c.func_8008D594(0);
    _ = c.func_8008B4C8(1);
    c.func_8008E480(0);
    c.func_80095B70(0);

    v.g.D_800F1968().* = 0;
}
