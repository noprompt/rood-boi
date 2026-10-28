//! Battle frame dispatch on state flag 0xAB: loot list, wind-down or the other path (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007B764 (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the loot list's head when state flag 0xAB is 3 or more, else the other path.
pub fn func_8007B764() callconv(.c) void {
    if (@as(c_int, c.vs_battle_getStateFlag(0xAB)) >= 3) {
        const head = v.g._lootListHead().*;
        if (head != null) {
            c.func_800CB158(@ptrCast(head));
            v.g._cameraMode().* = 4;
            c.func_8007B410();
            return;
        }
        c.func_8007B508();
        return;
    }
    c.func_8007B4C4();
}
