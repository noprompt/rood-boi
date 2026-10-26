//! Points the battle camera's look-at at a spherical offset from its position (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _setCameraLookAtFromAngles (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the camera's look-at point from yaw, pitch and distance around its position.
pub fn setCameraLookAtFromAngles(spherical: ?*v._sphericalValues) callconv(.c) void {
    const sph = spherical.?;
    const scratch = v.g.vs_scratch();

    scratch.camera.lookAt.vx = -%c.rsin(sph.yaw);
    scratch.camera.lookAt.vz = -%c.rcos(sph.yaw);

    // rsin(pitch) before rcos(pitch); the product wraps as the 32-bit C does.
    const negSinPitch: c_int = -%c.rsin(sph.pitch);
    scratch.camera.lookAt.vy = @divTrunc(negSinPitch *% 0x1000, c.rcos(sph.pitch));

    _ = c.VectorNormal(
        psx.cptr(c.VECTOR, &scratch.camera.lookAt),
        psx.cptr(c.VECTOR, &scratch.camera.lookAt),
    );

    scratch.camera.lookAt.vx = (scratch.camera.lookAt.vx *% sph.distance) +% scratch.camera.position.vx;
    scratch.camera.lookAt.vz = (scratch.camera.lookAt.vz *% sph.distance) +% scratch.camera.position.vz;
    scratch.camera.lookAt.vy = (scratch.camera.lookAt.vy *% sph.distance) +% scratch.camera.position.vy;
}
