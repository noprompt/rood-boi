//! Lerps a vector between two SVECTORs component by component (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D169C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Lerps each component of `from` toward `to` by `t` and stores the result in `out`.
pub fn func_800D169C(from: ?*v.SVECTOR, to: ?*v.SVECTOR, t: c_int, out: ?*v.SVECTOR) callconv(.c) void {
    const vx = c.vs_battle_lerp(@as(c_int, from.?.vx), @as(c_int, to.?.vx), t);
    out.?.vx = psx.conv(i16, vx);
    const vy = c.vs_battle_lerp(@as(c_int, from.?.vy), @as(c_int, to.?.vy), t);
    out.?.vy = psx.conv(i16, vy);
    const vz = c.vs_battle_lerp(@as(c_int, from.?.vz), @as(c_int, to.?.vz), t);
    out.?.vz = psx.conv(i16, vz);
}
