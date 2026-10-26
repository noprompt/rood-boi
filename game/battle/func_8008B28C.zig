//! Advances the battle timer by the tick speed while its hold flag is clear (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: func_8008B28C (src/BATTLE/BATTLE.PRG/146C.c)
/// Adds the tick speed to the battle timer unless D_800F1BA4 is set.
pub fn func_8008B28C() callconv(.c) void {
    if (v.g.D_800F1BA4().* == 0) {
        const sum: c_int = @as(c_int, v.g.D_800F1CDC().*) +% v.g.vs_gametime_tickspeed().*;
        v.g.D_800F1CDC().* = psx.conv(u16, sum);
    }
}
