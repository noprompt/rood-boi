//! Re-applies a battle actor's weapon and shield to func_80077130 (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007CAA4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sends battle actor `arg0`'s weapon blade and shield base to func_80077130.
pub fn func_8007CAA4(arg0: c_int) callconv(.c) void {
    const slot = psx.at(v.g.vs_battle_actors(), arg0).*;
    if (slot) |actor| {
        if (psx.get(actor.stats)) |stats| {
            if (stats.weapon.blade.id != 0) {
                c.func_80077130(@ptrCast(actor), arg0, @as(c_int, stats.weapon.wepId), 0, @as(c_int, stats.weapon.blade.material));
            } else {
                c.func_80077130(@ptrCast(actor), arg0, 0, 0, 0);
            }
            if (stats.shield.base.id != 0) {
                c.func_80077130(@ptrCast(actor), arg0, @as(c_int, stats.shield.wepId), 1, @as(c_int, stats.shield.base.material));
            } else {
                c.func_80077130(@ptrCast(actor), arg0, 0, 0, 0);
            }
        }
    }
}
