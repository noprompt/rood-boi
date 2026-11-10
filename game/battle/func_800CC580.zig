//! Battle drawing area: the 64-wide column of the second frame buffer page `arg1` names (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).
const sprite_item = @import("common").sprite_item;

/// orig: func_800CC580 (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// Sets the drawing area to the 64 x 256 column at x = `arg1`, y = 256 and the draw offset there.
pub fn func_800CC580(arg0: [*c]c_uint, arg1: c_int) callconv(.c) void {
    sprite_item.area(arg0, arg1 & 0x3FF, 256, 64, 256, .{ arg1, 256 });
}
