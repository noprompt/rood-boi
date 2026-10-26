//! Resets the battle clock and publishes it in state flags 0xA0..0xA3 (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007BCCC (src/BATTLE/BATTLE.PRG/146C.c)
/// Zeroes the battle clock, sets state flags 0xA0..0xA3 from it, then runs func_800CB560.
pub fn func_8007BCCC() callconv(.c) void {
    const clock = v.g.D_80050468();
    clock.unk0 = 0;
    clock.hours = 0;
    clock.minutes = 0;
    clock.seconds = 0;
    clock.frames = 0;
    c.vs_battle_setStateFlag(0xA0, 0);
    c.vs_battle_setStateFlag(0xA1, psx.conv(u8, clock.seconds));
    c.vs_battle_setStateFlag(0xA2, psx.conv(u8, clock.minutes));
    c.vs_battle_setStateFlag(0xA3, psx.conv(u8, clock.hours));
    c.func_800CB560();
}
