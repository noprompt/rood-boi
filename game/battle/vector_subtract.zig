//! Vector subtraction, `dst = a - b` component-wise (pc/src/game/BATTLE/BATTLE.PRG/4A0A8.c).
const v = @import("views_4A0A8");

/// orig: _vectorSubtract (pc/src/game/BATTLE/BATTLE.PRG/4A0A8.c)
/// Stores the component-wise difference `a - b` in `dst` and returns `dst`.
pub fn vectorSubtract(dst: ?*v.VECTOR, a: ?*v.VECTOR, b: ?*v.VECTOR) callconv(.c) ?*v.VECTOR {
    const out = dst.?;
    out.vx = a.?.vx -% b.?.vx;
    out.vy = a.?.vy -% b.?.vy;
    out.vz = a.?.vz -% b.?.vz;
    return dst;
}
