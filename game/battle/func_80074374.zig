//! Steers a battle actor's stack point toward the target func_800A1108 reports
//! (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80074374 (src/BATTLE/BATTLE.PRG/146C.c)
/// Reads the target point from func_800A1108 and steps toward it; returns 0 when func_8009E480 reports a block.
pub fn func_80074374() callconv(.c) c_int {
    var sp10: v.SVECTOR = undefined;
    // sp18 is filled by func_800A1108; the elements read below are the ones it writes.
    var sp18: [6]i16 = undefined;

    _ = c.func_800A1108(0, @ptrCast(&sp18));
    sp10.vx = sp18[2];
    sp10.vz = sp18[4];
    sp10.vy = psx.conv(i16, @as(c_int, sp18[3]) -% 0x5A);
    const temp_s0: c_int = c._stepTowardTarget(psx.cptr(c.SVECTOR, &sp10), 1, 0x28);

    if (c.func_8009E480() != 0) {
        return 0;
    }
    return temp_s0;
}
