//! Places a point at a yaw, pitch and distance from a base position (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _computeSphericalOffset (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets outPosition to basePosition plus the unit vector at angles' yaw and pitch, scaled by its distance.
pub fn computeSphericalOffset(outPosition: ?*v.VECTOR, basePosition: ?*v.VECTOR, angles: ?*v._sphericalValues) callconv(.c) void {
    outPosition.?.vx = c.rsin(angles.?.yaw);
    outPosition.?.vz = c.rcos(angles.?.yaw);
    const sinPitch: c_int = c.rsin(angles.?.pitch);
    outPosition.?.vy = @divTrunc(sinPitch *% 4096, c.rcos(angles.?.pitch));
    _ = c.VectorNormal(psx.cptr(c.VECTOR, outPosition.?), psx.cptr(c.VECTOR, outPosition.?));
    outPosition.?.vx = outPosition.?.vx *% angles.?.distance +% basePosition.?.vx;
    outPosition.?.vz = outPosition.?.vz *% angles.?.distance +% basePosition.?.vz;
    outPosition.?.vy = outPosition.?.vy *% angles.?.distance +% basePosition.?.vy;
}
