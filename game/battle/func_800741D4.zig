//! Camera mode and the field/battle transition for the battle overlay (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_800741D4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the camera mode to 2 and runs the transition for the current scene, at a faster tick speed when the scene state is 8.
pub fn func_800741D4() callconv(.c) void {
    v.g._cameraMode().* = 2;
    if (v.g.D_800F196C().* == 8) {
        v.g.vs_gametime_tickspeed().* = 4;
        c.func_80073D30(@ptrCast(psx.get(v.g.D_800F1910().unk0)), @ptrCast(&v.g.D_800F1910().unk4), v.g.D_800F1910().unk4.unkC);
        return;
    }
    c.func_80073E30(@ptrCast(psx.get(v.g.D_800F1910().unk0)), v.g.D_800F1910().unk4.unkC);
}
