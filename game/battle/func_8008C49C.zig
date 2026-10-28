//! Room section 12: sets one entry's 7-bit flag and clears its counter when shown (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: func_8008C49C (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets room section 12 entry `index`'s 7-bit field to `value`, clearing its counter when `value` is not negative; returns 0 when the room has no section 12.
pub fn func_8008C49C(index: c_int, value: c_int) callconv(.c) c_int {
    if (psx.get(v.g.vs_battle_roomData().section12)) |section12| {
        psx.setBits(psx.at(section12, index), "unk4_1", psx.conv(u7, value));
        if (value >= 0 and v.g.D_800F1D68().* == 0) {
            psx.at(v.g.D_800F1D70(), index).* = 0;
        }
        return 1;
    }
    return 0;
}
