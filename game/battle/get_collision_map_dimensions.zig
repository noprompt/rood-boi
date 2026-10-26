//! Collision map dimensions of the current battle room (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: _getCollisionMapDimensions (src/BATTLE/BATTLE.PRG/146C.c)
/// Packs the room's collision map size: height from bit 20 up, width times 16 in the low 16 bits; 0 without a map.
pub fn getCollisionMapDimensions(_: c_int) callconv(.c) c_int {
    const section = psx.get(v.g.vs_battle_roomData().collisionMapSection);
    if (section) |s| {
        // height << 0x14 on an int: the shift wraps, the bits above 31 are dropped.
        const height: c_uint = psx.conv(c_uint, @as(c_int, s.height)) << 20;
        // (u_short)(width * 16): the product is an int, truncated to 16 bits.
        const width: u16 = psx.conv(u16, @as(c_int, s.width) *% 16);
        return @bitCast(height | @as(c_uint, width));
    }
    return 0;
}
