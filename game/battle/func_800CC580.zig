//! Adds the drawing area and draw offset commands for a clip rectangle
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const c = @import("c_5BF94");

/// orig: func_800CC580 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Adds the GP0 drawing area (top-left and bottom-right) and draw offset commands for the rectangle at `pos`.
pub fn func_800CC580(arg0: [*c]c_uint, arg1: c_int) callconv(.c) void {
    // arg1 | 0xE3040000 etc.: the OR is unsigned; arg1 + 0x3F is int arithmetic, wrapping before the OR.
    c.vs_battle_addTile(
        arg0,
        psx.conv(c_int, psx.conv(c_uint, arg1) | 0xE304_0000),
        psx.conv(c_int, psx.conv(c_uint, arg1 +% 0x3F) | 0xE407_FC00),
        psx.conv(c_int, psx.conv(c_uint, arg1) | 0xE508_0000),
    );
}
