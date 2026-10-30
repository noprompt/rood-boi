//! Map completion percentage from the room flags (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: vs_battle_getMapCompletion (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the map-complete flag on room word 1 and returns the percentage of map flags set.
pub fn getMapCompletion() callconv(.c) c_int {
    const status = v.g.vs_main_mapStatus();
    if ((status.roomFlags[1] & 0x800000) != 0) {
        status.roomFlags[1] |= 0x400000;
    }

    const flags = v.g.vs_battle_mapCompletionFlags();
    var value: c_int = 0;
    var i: usize = 0;
    while (i < 16) : (i += 1) {
        var j: usize = 0;
        while (j < 32) : (j += 1) {
            const bit: c_int = @as(c_int, 1) << @as(u5, @intCast(j));
            if ((status.roomFlags[i] & flags[i] & bit) != 0) {
                value +%= 1;
            }
        }
    }
    return @divTrunc(value *% 100, 361);
}
