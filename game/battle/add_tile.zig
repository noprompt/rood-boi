//! Links one four-word primitive into an ordering table and advances the scratchpad primitive cursor (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

const TileItem = *const fn ([*c]c_uint, c_uint, c_uint, c_uint) callconv(.c) c_int;

/// orig: vs_battle_addTile (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// Writes a tile primitive at the scratchpad cursor, links it after `before` and advances the cursor.
pub fn addTile(before: [*c]c_uint, rgb0: c_int, xy: c_int, wh: c_int) callconv(.c) void {
    // A tile or a line, as a draw item (vs_battle_tileItem); the words that are neither (the callers' draw mode and texture
    // window pairs) stay the packet they were.
    if (psx.weak(TileItem, "vs_battle_tileItem")) |item| {
        if (item(before, psx.conv(c_uint, rgb0), psx.conv(c_uint, xy), psx.conv(c_uint, wh)) != 0) return;
    }
    const prim: [*]align(1) c_uint = @ptrCast(psx.get(v.g.vs_scratch().unk0).?);
    prim[0] = (before.* & 0xFFFFFF) | 0x03000000;
    prim[1] = psx.conv(c_uint, rgb0);
    prim[2] = psx.conv(c_uint, xy);
    prim[3] = psx.conv(c_uint, wh);
    before.* = (psx.addr(prim) << 8) >> 8;
    psx.put(&v.g.vs_scratch().unk0, @as(?*anyopaque, @ptrCast(prim + 4)));
}
