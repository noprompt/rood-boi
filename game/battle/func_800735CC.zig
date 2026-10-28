//! Clears a battle record's first halfword between two battle helper calls (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");
const v = @import("views_146C");

/// orig: func_800735CC (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs func_800CB114, clears the first halfword of arg0, then runs func_8006C40C.
pub fn func_800735CC(arg0: ?*v.D_800F18EC_t) callconv(.c) void {
    c.func_800CB114();
    arg0.?.unk0 = 0;
    c.func_8006C40C();
}
