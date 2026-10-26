//! Sets each scene room's visited flag from the map's room flags (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: vs_battle_setRoomsUnk0 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets every scene room's visited flag from the map's room flags, by its location id.
pub fn setRoomsUnk0(scene: ?*v.vs_battle_scene) callconv(.c) void {
    const sc = scene.?;
    const roomCount: c_int = sc.roomCount;
    var i: c_int = 0;
    while (i < roomCount) : (i +%= 1) {
        const room = psx.at(&sc.rooms, i);
        const locationId: c_int = c._getLocationId(@as(c_int, room.zoneId), @as(c_int, room.mapId) -% 1);
        if (locationId > 0) {
            // locationId & 0x1F is always 0..31: the shift amount is in range.
            const shift: u5 = @intCast(locationId & 0x1F);
            room.visited = psx.at(&v.g.vs_main_mapStatus().roomFlags, locationId >> 5).* & (@as(c_int, 1) << shift);
        } else {
            room.visited = 0;
        }
    }
}
