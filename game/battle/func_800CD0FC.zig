//! Sets the default sprite for slot `arg1` and patches word 4 of its result
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CD0FC (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Sets the default sprite of slot `arg1` (below 3) and stores a table word at its index 4.
pub fn func_800CD0FC(arg0: c_int, arg1: c_uint) callconv(.c) void {
    if (arg1 < 3) {
        // The right-hand table load happens before the call: the call may change
        // the table's bytes, and the object reads the value first.
        const value = psx.conv(c_uint, v.g.D_800EC2D8()[arg1]);
        const sprite = c.vs_battle_setSpriteDefault(
            v.g.D_800EC2CC()[arg1],
            (@as(c_int, arg0) << 16) | 0xA,
        );
        sprite[4] = value;
    }
}
