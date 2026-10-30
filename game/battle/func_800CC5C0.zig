//! Battle tile primitive: queues one tile packet built from the colour and position word (src/BATTLE/BATTLE.PRG/5BF94.c).
const c = @import("c_5BF94");

/// orig: func_800CC5C0 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Adds a tile to the packet at `arg0`, with colour, position and size derived from `arg1`.
pub fn func_800CC5C0(arg0: [*c]c_uint, arg1: c_int) callconv(.c) void {
    // C computes these in unsigned int (0xE3000000 etc. do not fit int); the
    // position sum is int arithmetic that wraps.
    const rgb: c_uint = @as(c_uint, @bitCast(arg1)) | 0xE3000000;
    const xy: c_uint = @as(c_uint, @bitCast(arg1 +% 0x13F)) | 0xE403BC00;
    const wh: c_uint = @as(c_uint, @bitCast(arg1)) | 0xE5000000;
    c.vs_battle_addTile(arg0, @bitCast(rgb), @bitCast(xy), @bitCast(wh));
}
