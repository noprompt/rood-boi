//! Clamps a camera position into the zone bounds (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: _clampPositionToZoneBounds (src/BATTLE/BATTLE.PRG/146C.c)
/// Clamps the XZ position into the zone bounds, inset by the camera's entity radius, and sets Y from the look-at height.
pub fn clampPositionToZoneBounds(inPos: ?*v.VECTOR, outPos: ?*v.VECTOR) callconv(.c) void {
    const in = inPos.?;
    const out = outPos.?;
    const zone = v.g._zoneContext();
    const cam = v.g.vs_battle_cameraCurrentSpherical();
    const scratch = v.g.vs_scratch();

    const entityRadius: c_int = @divTrunc(cam.values.distance *% 4096, 2304);

    // X axis
    var bound: c_int = (@as(c_int, zone.bounds.minX) *% 4096 *% 128) +% (entityRadius *% 360);
    var maxBound: c_int = (@as(c_int, zone.bounds.maxX) *% 4096 *% 128) -% (entityRadius *% 360);

    if (maxBound < bound) {
        out.vx = (bound +% maxBound) >> 1;
    } else if (in.vx < bound) {
        out.vx = bound;
    } else if (maxBound < in.vx) {
        out.vx = maxBound;
    } else {
        out.vx = in.vx;
    }

    // Z axis
    bound = (@as(c_int, zone.bounds.minZ) *% 4096 *% 128) +% (entityRadius *% 360);
    maxBound = (@as(c_int, zone.bounds.maxZ) *% 4096 *% 128) -% (entityRadius *% 360);

    if (maxBound < bound) {
        out.vz = (bound +% maxBound) >> 1;
    } else if (in.vz < bound) {
        out.vz = bound;
    } else if (maxBound < in.vz) {
        out.vz = maxBound;
    } else {
        out.vz = in.vz;
    }

    // Round X and Z down to whole units.
    out.vx &= ~@as(c_int, 4096 - 1);
    out.vz &= ~@as(c_int, 4096 - 1);

    // Y axis: keep the input height unless it is out of the look-at band.
    const yBound: c_int = in.vy -% scratch.camera.lookAt.vy;
    const lowLimit: c_int = -393216; // -(ONE * 96)
    if (yBound > 393216 or yBound < lowLimit) {
        out.vy = in.vy;
    } else {
        out.vy = scratch.camera.lookAt.vy;
    }
    if (out.vy > 0) {
        out.vy = 0;
    }
}
