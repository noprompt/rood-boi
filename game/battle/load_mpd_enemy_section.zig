//! Loads the zone's MPD enemy section into the zone context (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _loadMpdEnemySection (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies `dataLen` bytes of MPD enemy records into a new heap block and records the count, or clears the section when empty.
pub fn loadMpdEnemySection(data: ?*anyopaque, dataLen: c_uint) callconv(.c) void {
    const ctx = v.g._zoneContext();
    if (dataLen != 0) {
        const enemies: ?*v._mpdEnemy = @ptrCast(@alignCast(c.vs_main_allocHeap(dataLen)));
        psx.put(&ctx.mpdEnemies, enemies);
        c.vs_main_memcpy(psx.get(ctx.mpdEnemies), data, dataLen);
        ctx.mpdEnemyCount = psx.conv(u32, dataLen / @sizeOf(v._mpdEnemy));
        return;
    }
    psx.put(&ctx.mpdEnemies, null);
    ctx.mpdEnemyCount = 0;
}
