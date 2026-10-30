//! Rotates the scratchpad vector table D_800F1D98 by its angles (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80090B28 (src/BATTLE/BATTLE.PRG/146C.c)
/// Recomputes the three rotated components in D_800F1D98[0..2] from its angles and scale.
pub fn func_80090B28() callconv(.c) void {
    const d = v.g.D_800F1D98();

    var s0: c_int = c.rsin(@as(c_int, d[5]));
    const t1: c_int = c.rcos(@as(c_int, d[4]));
    s0 *%= @as(c_int, d[6]);
    if (s0 < 0) s0 +%= 0xFFF;
    var v0: c_int = (s0 >> 12) *% t1;
    if (v0 < 0) v0 +%= 0xFFF;
    d[0] = psx.conv(i16, v0 >> 12);

    s0 = c.rcos(@as(c_int, d[5]));
    const t2: c_int = c.rcos(@as(c_int, d[4]));
    s0 = -%s0;
    s0 *%= @as(c_int, d[6]);
    if (s0 < 0) s0 +%= 0xFFF;
    v0 = (s0 >> 12) *% t2;
    if (v0 < 0) v0 +%= 0xFFF;
    d[2] = psx.conv(i16, v0 >> 12);

    v0 = c.rsin(@as(c_int, d[4])) *% @as(c_int, d[6]);
    if (v0 < 0) v0 +%= 0xFFF;
    d[1] = psx.conv(i16, v0 >> 12);
}
