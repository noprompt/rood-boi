//! Refreshes the per-zone record table (D_80061078) when the zone changes and ages the other records (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80089A00 (src/BATTLE/BATTLE.PRG/146C.c)
/// Finds or replaces this zone's record, copies enemy data into it, and ages the other records.
pub fn func_80089A00() callconv(.c) void {
    const zone = v.g._zoneContext();
    const records = v.g.D_80061078();
    var found: c_int = 0;
    var i: c_int = 0;
    var j: c_int = 0;

    while (j < 4) : (j +%= 1) {
        const rec = &records[@intCast(j)];
        if (rec.unk0 != 0 and @as(c_int, rec.zndId) == zone.zndId and @as(c_int, rec.mapId) == zone.mapId) {
            found = 1;
            v.g.D_80060064().* = j;
            while (psx.conv(c_uint, i) < zone.mpdEnemyCount) : (i +%= 1) {
                const temp: ?[*]u8 = @ptrCast(c.func_80069E80(i));
                if (temp) |t| {
                    // The list is only dereferenced here, as in the C (its pointer may be null without a match).
                    psx.at(psx.get(zone.mpdEnemies).?, i).unk2 = t[1];
                }
            }
            break;
        }
    }

    if (found == 0) {
        i = 0;
        j = 0;
        while (j < 4) : (j +%= 1) {
            if (records[@intCast(j)].unk0 < records[@intCast(i)].unk0) {
                i = j;
            }
        }
        v.g.D_80060064().* = i;
        c.vs_main_bzero(&records[@intCast(i)], @as(c_int, @sizeOf(v.D_80061078_t)));
    }

    i = 0;
    while (i < 4) : (i +%= 1) {
        const cur: usize = @intCast(v.g.D_80060064().*);
        if (records[cur].unk0 < records[@intCast(i)].unk0) {
            records[@intCast(i)].unk0 -%= 1;
        }
    }

    const slot: usize = @intCast(v.g.D_80060064().*);
    records[slot].unk0 = 4;
    records[slot].zndId = psx.conv(u8, zone.zndId);
    records[slot].mapId = psx.conv(u16, zone.mapId);
}
