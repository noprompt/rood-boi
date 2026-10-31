//! Byte copy used by the battle overlay, copying from the highest index down
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;

/// orig: vs_battle_rMemcpy (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Copies `size` bytes from `src` to `dest` one byte at a time, last index first.
pub fn rMemcpy(dest: ?*anyopaque, src: ?*const anyopaque, size: c_int) callconv(.c) void {
    const d: [*]u8 = @ptrCast(dest.?);
    const s: [*]const u8 = @ptrCast(src.?);
    // do-while: the first pass always runs; size wraps like C's int when it is <= 0.
    var n: c_int = size;
    while (true) {
        n = n -% 1;
        psx.at(d, n).* = psx.at(s, n).*;
        if (n == 0) break;
    }
}
