//! The battle's post-action step: loot pickup or the battle-end path (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8006FB48 (src/BATTLE/BATTLE.PRG/146C.c)
/// Once state flag 0xAB exceeds 2, starts the loot pickup if loot is waiting, else runs the other tail.
pub fn func_8006FB48() callconv(.c) void {
    if (c.vs_battle_getStateFlag(0xAB) > 2) {
        if (v.g._lootListHead().* != null) {
            c.func_800CB158(@ptrCast(v.g._lootListHead().*));
            v.g.D_800F196C().* = 2;
            v.g._cameraMode().* = 12;
            c.func_8006C39C();
        } else {
            c.func_8006F89C();
        }
        return;
    }
    c.func_8006F5FC();
}
