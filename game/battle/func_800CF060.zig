//! Flips a battle flag, runs two battle steps around a display call and returns their OR (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CF060 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Toggles D_800EC2E4, runs two battle steps, and calls func_800D2560 when D_800F531C is 4.
pub fn func_800CF060() callconv(.c) c_int {
    const flag = v.g.D_800EC2E4();
    flag.* = psx.conv(u8, @as(c_int, 1) -% @as(c_int, flag.*));
    c.func_800D7890(1);
    const temp_s1 = c.func_800CE9B0();
    c.func_800D7890(0);
    const temp_s0 = c.func_800CED60();
    c.func_800D7890(1);
    if (v.g.D_800F531C().* == 4) c.func_800D2560();
    return temp_s1 | temp_s0;
}
