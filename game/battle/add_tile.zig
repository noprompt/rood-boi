//! Adds a flat tile to an ordering table as a draw item (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;

const TileItem = *const fn ([*c]c_uint, c_uint, c_uint, c_uint) callconv(.c) c_int;

/// orig: vs_battle_addTile (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// A flat tile (or a flat line: the callers' words are those) placed where it linked, as a draw item (vs_battle_tileItem).
pub fn addTile(before: [*c]c_uint, rgb0: c_int, xy: c_int, wh: c_int) callconv(.c) void {
    if (psx.weak(TileItem, "vs_battle_tileItem")) |item|
        _ = item(before, psx.conv(c_uint, rgb0), psx.conv(c_uint, xy), psx.conv(c_uint, wh));
}
