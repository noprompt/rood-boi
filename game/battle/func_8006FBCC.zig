//! Battle cleanup on a new turn: clears the enemy actors that are not the target and resets the camera and tick speed (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8006FBCC (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the per-actor cleanup for slots 0..15 (except the target), then resets the camera, the CLUT state and the tick speed.
pub fn func_8006FBCC(arg0: c_int) callconv(.c) void {
    var i: c_int = 0;
    while (i < 16) : (i +%= 1) {
        // Each condition is evaluated in C's order and short-circuits the same way.
        if (i != @as(c_int, v.g.D_800F19CC().*.?.unk8.unk4.unk0.targetActor) and
            (c.func_800A0BE0(i) & 0x01000000) == 0 and
            (c.func_800A0BE0(i) & 1) != 0)
        {
            c.func_8009E5C4(i);
        }
    }
    c.func_8007B10C(8, 4, 0, 0, 0);
    c.func_8006C250();
    c.vs_main_setClutState(1);
    c.func_8008B4BC(0);
    c.func_80095B70(0);
    v.g.D_800F18FC().* = arg0;
    v.g.vs_gametime_tickspeed().* = 2;
    v.g._cameraMode().* = 0xB;
}
