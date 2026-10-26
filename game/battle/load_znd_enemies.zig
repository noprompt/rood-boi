//! Loads the zone's ZND enemy tables into heap blocks (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _loadZndEnemies (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies the zone's enemy count, zud file table and enemy records into heap blocks; clears both pointers when there are none.
pub fn loadZndEnemies(data: [*c]c_int, _: c_int) callconv(.c) void {
    const zc = v.g._zoneContext();
    zc.zndEnemyCount = data[0];

    if (zc.zndEnemyCount != 0) {
        // count * 8 is an int product (wraps), then converted to u_int.
        psx.put(&zc.zudFiles, c.vs_main_allocHeap(psx.conv(c_uint, zc.zndEnemyCount *% 8)));
        // count * sizeof (size_t): only the low 32 bits reach the u_int parameter, so wrapping u32 is exact.
        c.vs_main_memcpy(
            psx.get(zc.zudFiles),
            @ptrCast(psx.at(data, 1)),
            psx.conv(c_uint, zc.zndEnemyCount) *% @sizeOf(v.vs_main_CdFile),
        );
        psx.put(&zc.zndEnemies, c.vs_main_allocHeap(psx.conv(c_uint, zc.zndEnemyCount) *% @sizeOf(v._zndEnemy)));
        // data + (count * 2 + 1): int arithmetic, then the pointer offset.
        c.vs_main_memcpy(
            psx.get(zc.zndEnemies),
            @ptrCast(psx.at(data, (zc.zndEnemyCount *% 2) +% 1)),
            psx.conv(c_uint, zc.zndEnemyCount) *% @sizeOf(v._zndEnemy),
        );
        return;
    }

    psx.put(&zc.zudFiles, null);
    psx.put(&zc.zndEnemies, null);
}
