//! Sets the collision flag of a room cell or section-12 entry (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: func_8008B808 (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores the 3-bit flag `arg3` (nonzero becomes 5) at a room cell (arg2 < 2) or a section-12 entry (arg2 >= 2); returns 1 if stored, else 0.
pub fn func_8008B808(arg0: c_int, arg1: c_int, arg2: c_int, arg3: c_int) callconv(.c) c_int {
    var value = arg3;
    const room = v.g.vs_battle_roomData();
    if (psx.get(room.section3) != null) {
        if (value != 0) value = 5;
        if (arg2 >= 2) {
            if (psx.get(room.section12)) |section12| {
                // arg2 >= 2: the subtraction cannot overflow.
                psx.setBits(&psx.at(section12, arg2 -% 2).unkB4, "unk0_10", psx.conv(u3, value));
                return 1;
            }
        } else {
            const section3 = psx.get(room.section3).?;
            const cmap = psx.get(room.collisionMapSection).?;
            const width: c_int = cmap.width;
            const height: c_int = cmap.height;
            const index: c_int = arg2 *% width *% height +% arg1 *% width +% arg0;
            psx.setBits(psx.at(section3, index), "unk0_10", psx.conv(u3, value));
            return 1;
        }
    }
    return 0;
}
