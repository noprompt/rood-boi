//! Starts a screen transition into a door's room and loads its map (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007C4E0 (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies a room door section into the transition state with `effect` and `speed`, then loads its map.
pub fn func_8007C4E0(door: ?*v._mpdRoomDoorSection_t, effect: c_int, speed: c_int) callconv(.c) c_int {
    v.g.D_800F1AB0().* = door.?.*;
    v.g.vs_battle_screenTransitionStep().* = 1;
    v.g.vs_battle_screenTransitionEffect().* = effect;
    v.g.vs_battle_screenTransitionSpeed().* = speed;
    v.g.D_800F1AB0().zndId = psx.conv(u8, v.g._zoneContext().zndId);
    c._loadMpd(@as(c_int, door.?.mpdId));
    c.func_8009E5C4(0);
    c.func_800A0A1C(0, 1);
    c.func_8008B8F8(null);

    return 1;
}
