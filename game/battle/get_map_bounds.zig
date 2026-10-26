//! Map bounds of the current battle room, from its section 18 (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: _getMapBounds (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the room's map bounds (section 18), or null when the room has none.
pub fn getMapBounds(_: c_int) callconv(.c) ?*v._zoneContextBounds {
    if (psx.get(v.g.vs_battle_roomData().section18) != null) {
        return psx.get(v.g.vs_battle_roomData().section18);
    }
    return null;
}
