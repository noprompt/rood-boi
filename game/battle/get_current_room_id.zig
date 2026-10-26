//! The current room id, from the zone context (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: vs_battle_getCurrentRoomId (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the location id of the zone and map held in the zone context.
pub fn getCurrentRoomId() callconv(.c) c_int {
    const zone = v.g._zoneContext();
    return c._getLocationId(zone.zndId, zone.mapId);
}
