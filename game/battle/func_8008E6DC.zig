//! Marks the room-zone entries for section `arg0` as visited in the state flags (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: func_8008E6DC (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the state flag of the first entry in section `arg0` whose zone and map match the current room.
pub fn func_8008E6DC(arg0: c_int) callconv(.c) void {
    const scene = psx.get(v.g.vs_battle_roomData().sectionF).?;
    const room = psx.at(&scene.rooms, 0);
    const zoneId: c_int = room.zoneId;
    const mapId: c_int = room.mapId;

    // D_800E84AC[i][k] of the static helper get_D_800E84AC: four bytes per row.
    const table = @as([*][4]u8, @ptrCast(psx.globalMany(u8, "D_800E84AC")));
    const sections = v.g.D_800E849C();
    const flags = v.g.vs_main_stateFlags();

    var i: c_int = @as(c_int, psx.at(sections, arg0).*);
    while (i < @as(c_int, psx.at(sections, arg0 +% 1).*)) : (i +%= 1) {
        const row = psx.at(table, i);
        if ((@as(c_int, row[0]) == zoneId and @as(c_int, row[1]) == mapId) or
            (@as(c_int, row[2]) == zoneId and @as(c_int, row[3]) == mapId))
        {
            psx.at(&flags.unk186, i).* = 1;
            return;
        }
    }
}
