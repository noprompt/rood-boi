//! Takes one of a miscellaneous item out of the inventory (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

/// orig: vs_battle_decreaseMiscCount (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Takes one of item `miscId` from the misc inventory, clearing its slot at zero; the search starts at the last invoked slot.
pub fn decreaseMiscCount(miscId: c_int) callconv(.c) c_int {
    if (miscId < 0x143) {
        v.g.vs_battle_miscItemInvoked().* = 0;
    }
    const invoked: c_int = v.g.vs_battle_miscItemInvoked().*;
    var i: c_int = 0;
    while (i < 64) : (i += 1) {
        // invoked is 0..255 and i is 0..63, so the sum cannot overflow; the masked index is 0..63.
        const miscIndex: usize = @intCast((invoked +% i) & 0x3F);
        const misc = &v.g.vs_main_inventory().misc[miscIndex];
        if (@as(c_int, misc.id) == miscId) {
            // The count is kept as an int: a stored 0 wraps to -1 and does not clear the slot.
            const count: c_int = @as(c_int, misc.count) -% 1;
            misc.count = psx.conv(u8, count);
            if (count == 0) {
                misc.id = 0;
            }
            return 1;
        }
    }
    return 0;
}
