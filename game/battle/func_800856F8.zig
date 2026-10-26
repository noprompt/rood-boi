//! Clears a 0x84C-byte battle block (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_800856F8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Zeroes the 0x84C-byte block at `block`.
pub fn func_800856F8(block: ?*anyopaque) callconv(.c) void {
    c.vs_main_bzero(block, 0x84C);
}
