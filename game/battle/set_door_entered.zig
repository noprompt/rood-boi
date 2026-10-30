//! Sets the main state flags' door-entered byte from the battle's door counter
//! (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: vs_battle_setDoorEntered (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores the battle's door-entered value plus one into the main state flags, truncated to a byte.
pub fn setDoorEntered() callconv(.c) void {
    const door: c_int = v.g.vs_battle_doorEntered().*;
    v.g.vs_main_stateFlags().doorEntered = psx.conv(u8, door +% 1);
}
