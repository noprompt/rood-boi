//! Looks up an actor's action cost by its battle slot (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80085978 (src/BATTLE/BATTLE.PRG/146C.c)
/// Passes the stats block of battle actor `arg1` to `_getActionCost` with `arg0` and a zero flag.
pub fn func_80085978(arg0: c_int, arg1: c_int) callconv(.c) void {
    const actor = psx.get(psx.at(v.g.vs_battle_actors(), arg1).*.?.stats);
    _ = c._getActionCost(psx.conv(c_uint, arg0), @ptrCast(actor), 0);
}
