//! Syncs the spherical camera's yaw, pitch and distance to the scratchpad camera position
//! (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: vs_battle_syncCameraAnglesFromPosition (src/BATTLE/BATTLE.PRG/146C.c)
/// Derives the view direction from the camera position and look-at point, stores the angles in the scratchpad, and fills the spherical camera when given.
pub fn syncCameraAnglesFromPosition(camera: ?*v._sphericalCamera) callconv(.c) c_int {
    const scratch = v.g.vs_scratch();

    var toCamera: v.VECTOR = undefined;
    var toCameraNorm: v.VECTOR = undefined;

    toCamera.vx = @divTrunc(scratch.camera.position.vx -% scratch.camera.lookAt.vx, 4096);
    toCamera.vz = @divTrunc(scratch.camera.position.vz -% scratch.camera.lookAt.vz, 4096);
    toCamera.vy = @divTrunc(scratch.camera.position.vy -% scratch.camera.lookAt.vy, 4096);

    _ = c.VectorNormal(psx.cptr(c.VECTOR, &toCamera), psx.cptr(c.VECTOR, &toCameraNorm));

    var yaw: c_int = c.ratan2(toCameraNorm.vx, toCameraNorm.vz);
    yaw = @rem(yaw +% 4096, 4096);
    scratch.camera.angles.vy = yaw;

    const horiz: c_int = @divTrunc(toCameraNorm.vx *% toCameraNorm.vx, 4096) +%
        @divTrunc(toCameraNorm.vz *% toCameraNorm.vz, 4096);
    const pitch: c_int = c.ratan2(toCameraNorm.vy, c.SquareRoot12(horiz));
    scratch.camera.angles.vx = pitch;

    if (camera) |sph| {
        sph.values.yaw = yaw;
        sph.values.pitch = pitch;
        if (toCamera.vx != 0) {
            sph.values.distance = @divTrunc(toCamera.vx *% 4096, toCameraNorm.vx);
        } else if (toCamera.vz != 0) {
            sph.values.distance = @divTrunc(toCamera.vz *% 4096, toCameraNorm.vz);
        } else {
            sph.values.distance = 4096 / 4;
        }
    }
    return yaw;
}
