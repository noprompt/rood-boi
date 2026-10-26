//! Sets the battle near clip distance and passes it on to func_80098160
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: vs_battle_setNearClip (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores the near clip distance and hands it to func_80098160.
pub fn setNearClip(nearClip: c_int) callconv(.c) void {
    v.g.vs_main_nearClip().* = nearClip;
    c.func_80098160(nearClip);
}
