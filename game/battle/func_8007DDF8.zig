//! Copies a 16-byte block into the global D_800F1A68 (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const v = @import("views_146C");

/// orig: func_8007DDF8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies the whole D_800F1A68 block from `src` into the global.
pub fn func_8007DDF8(src: ?*v.D_800F1A68_t) callconv(.c) void {
    v.g.D_800F1A68().* = src.?.*;
}
