//! Points the battle camera's look-at at a spherical offset from its position (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _setCameraLookAtFromAngles (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Sets the camera's look-at point from yaw, pitch and distance around its position.
pub fn setCameraLookAtFromAngles(spherical: ?*v._sphericalValues) callconv(.c) void {
    const sph = spherical.?;
    const view = v.g.vs_view();

    view.camera.lookAt.vx = -%c.rsin(sph.yaw);
    view.camera.lookAt.vz = -%c.rcos(sph.yaw);

    // rsin(pitch) before rcos(pitch); the product wraps as the 32-bit C does.
    const negSinPitch: c_int = -%c.rsin(sph.pitch);
    view.camera.lookAt.vy = @divTrunc(negSinPitch *% 0x1000, c.rcos(sph.pitch));

    _ = c.VectorNormal(
        psx.cptr(c.VECTOR, &view.camera.lookAt),
        psx.cptr(c.VECTOR, &view.camera.lookAt),
    );

    view.camera.lookAt.vx = (view.camera.lookAt.vx *% sph.distance) +% view.camera.position.vx;
    view.camera.lookAt.vz = (view.camera.lookAt.vz *% sph.distance) +% view.camera.position.vz;
    view.camera.lookAt.vy = (view.camera.lookAt.vy *% sph.distance) +% view.camera.position.vy;
}
