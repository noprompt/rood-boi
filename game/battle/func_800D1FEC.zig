//! Clears the D_800F54B8 slot and runs func_800D1DFC for each bit set in its argument (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D1FEC (src/BATTLE/BATTLE.PRG/5BF94.c)
/// For each bit i of `arg0` (0..3) set: marks slot i of D_800F54B8 with 0xFF and calls func_800D1DFC(1 << i).
pub fn func_800D1FEC(arg0: c_int) callconv(.c) void {
    // i runs 0..3 (i < 4 bounds it), so the increment cannot overflow.
    var i: c_int = 0;
    while (i < 4) : (i += 1) {
        if (((arg0 >> @intCast(i)) & 1) != 0) {
            v.g.D_800F54B8()[@intCast(i)].unk0 = 0xFF;
            c.func_800D1DFC(@as(c_int, 1) << @intCast(i));
        }
    }
}
