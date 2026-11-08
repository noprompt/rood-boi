//! Stores the plg load state (pc/src/game/BATTLE/BATTLE.PRG/6F014.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_6F014");

/// orig: vs_battle_setPlgLoadState (pc/src/game/BATTLE/BATTLE.PRG/6F014.c)
/// Sets the plg load state to `value`.
pub fn setPlgLoadState(value: c_int) callconv(.c) void {
    v.g._plgLoadState().* = psx.conv(u32, value);
}
