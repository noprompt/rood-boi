//! Adds an SVECTOR's components into a VECTOR, storing the sums in an output VECTOR
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

/// orig: _addSVectorToVector (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Writes vec plus svec, component by component, into out.
pub fn addSVectorToVector(svec: ?*v.SVECTOR, vec: ?*v.VECTOR, out: ?*v.VECTOR) callconv(.c) void {
    const s = svec.?;
    const d = vec.?;
    const o = out.?;
    // Read before the first store, as the C does: out may alias svec.
    const vy: c_int = s.vy;
    o.vx = d.vx +% @as(c_int, s.vx);
    o.vy = d.vy +% vy;
    o.vz = d.vz +% @as(c_int, s.vz);
    _ = psx;
}
