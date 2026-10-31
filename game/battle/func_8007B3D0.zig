//! Forwards a CLUT transition to the VRAM loader (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007B3D0 (src/BATTLE/BATTLE.PRG/146C.c)
/// Loads a CLUT transition, with its second argument offset by 4.
pub fn func_8007B3D0(arg0: c_int, arg1: c_int, arg2: [*c]c_ushort, arg3: c_int) callconv(.c) void {
    c.vs_main_loadClutTransition(arg0, arg1 +% 4, arg2, arg3);
}
