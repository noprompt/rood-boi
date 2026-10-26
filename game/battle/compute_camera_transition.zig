//! Camera transition setup: direction, frame count, look-at point and per-frame steps
//! toward a target position (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _computeCameraTransition (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets up the camera transition toward targetPosition: direction, frame count, look-at point and per-frame steps.
pub fn computeCameraTransition(targetPosition: ?*v.VECTOR) callconv(.c) void {
    const target = targetPosition.?;
    const scratch = v.g.vs_scratch();
    const ct = v.g.vs_battle_cameraTransition().*.?;
    var cameraToTarget: v.VECTOR = undefined;

    cameraToTarget.vx = @divTrunc(target.vx -% scratch.camera.position.vx, 4096);
    cameraToTarget.vz = @divTrunc(target.vz -% scratch.camera.position.vz, 4096);
    cameraToTarget.vy = @divTrunc(target.vy -% scratch.camera.position.vy, 4096);

    _ = c.VectorNormal(psx.cptr(c.VECTOR, &cameraToTarget), psx.cptr(c.VECTOR, &ct.direction));

    ct.transitionSpeed = 0x80;

    ct.targetPosition.vx = target.vx;
    ct.targetPosition.vy = target.vy;
    ct.targetPosition.vz = target.vz;

    cameraToTarget.vy = target.vy -% scratch.camera.position.vy;

    ct.transitionFrames = @divTrunc(cameraToTarget.vy, ct.direction.vy *% ct.transitionSpeed);

    ct.targetLookAt.vx = -%c.rsin(ct.toSpherical.values.yaw);
    ct.targetLookAt.vz = -%c.rcos(ct.toSpherical.values.yaw);
    ct.targetLookAt.vy = @divTrunc((-%c.rsin(ct.toSpherical.values.pitch)) *% 4096, c.rcos(ct.toSpherical.values.pitch));

    _ = c.VectorNormal(psx.cptr(c.VECTOR, &ct.targetLookAt), psx.cptr(c.VECTOR, &ct.targetLookAt));

    ct.targetLookAt.vx = (ct.targetLookAt.vx *% 0x900) +% ct.targetPosition.vx;
    ct.targetLookAt.vz = (ct.targetLookAt.vz *% 0x900) +% ct.targetPosition.vz;
    ct.targetLookAt.vy = (ct.targetLookAt.vy *% 0x900) +% ct.targetPosition.vy;

    ct.lookAtStep.vx = @divTrunc(ct.targetLookAt.vx -% scratch.camera.lookAt.vx, ct.transitionFrames);
    ct.lookAtStep.vz = @divTrunc(ct.targetLookAt.vz -% scratch.camera.lookAt.vz, ct.transitionFrames);
    ct.lookAtStep.vy = @divTrunc(ct.targetLookAt.vy -% scratch.camera.lookAt.vy, ct.transitionFrames);

    ct.farClipStep = @divTrunc(ct.toFarClip -% scratch.camera.farClip, ct.transitionFrames);
    ct.nearClipStep = @divTrunc(ct.toNearClip -% v.g.vs_main_nearClip().*, ct.transitionFrames);
    ct.projectionDistanceStep = @divTrunc(ct.toProjectionDistance -% v.g.vs_main_projectionDistance().*, ct.transitionFrames);
}
