//! Maps a zone id and a map id to a location index (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: _getLocationId (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the first location index whose zone and map ids match, or 0 when none does.
pub fn getLocationId(zoneId: c_int, mapId: c_int) callconv(.c) c_int {
    const ids = v.g.vs_main_locationZoneMapIds();
    var i: c_int = 0;
    while (i < 512) : (i +%= 1) {
        // i < 512: the index stays within the 1024-byte table.
        const idx: usize = @intCast(i);
        if (zoneId == @as(c_int, ids[idx * 2]) and mapId == @as(c_int, ids[idx * 2 + 1])) {
            return i;
        }
    }
    return 0;
}
