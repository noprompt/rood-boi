//! Counts the battle actors in the actor table whose allegiance matches a value (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: func_8007CF80 (src/BATTLE/BATTLE.PRG/146C.c)
/// Counts the occupied battle actor slots whose allegiance equals `arg0`.
pub fn func_8007CF80(arg0: c_int) callconv(.c) c_int {
    const actors = v.g.vs_battle_actors();
    var count: c_uint = 0;
    var i: usize = 0;
    // The loop bound is the 16 slots of vs_battle_actors.
    while (i < 16) : (i += 1) {
        if (actors[i]) |actor| {
            if (@as(c_int, actor.allegiance) == arg0) {
                count +%= 1;
            }
        }
    }
    return psx.conv(c_int, count);
}
