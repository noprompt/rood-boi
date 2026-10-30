//! Stores a value in the battle byte global D_800EB9AF (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

/// orig: func_800CB654 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Stores its argument in the byte global D_800EB9AF, truncated to 8 bits as the C does.
pub fn func_800CB654(arg0: c_int) callconv(.c) void {
    v.g.D_800EB9AF().* = psx.conv(u8, arg0);
}
