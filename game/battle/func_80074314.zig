//! Resets the camera mode and game tick speed, then runs two battle setup calls on the entry at D_800F1910 (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80074314 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the camera mode and tick speed, then calls two setup functions on the room entry's sections.
pub fn func_80074314() callconv(.c) void {
    v.g._cameraMode().* = 4;
    v.g.vs_gametime_tickspeed().* = 2;
    c.func_800CB50C();
    c.func_8008DEAC(psx.cptr(c._mpdRoomSection9, &psx.get(v.g.D_800F1910().unk0).?.unk0), 1);
    c.func_800E68EC(
        @as(c_int, psx.get(v.g.D_800F1910().unk0).?.unk0.unk0),
        @as(c_int, psx.get(v.g.D_800F1910().unk0).?.unk0.unk2),
    );
}
