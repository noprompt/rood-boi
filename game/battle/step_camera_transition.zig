//! The camera transition step: moves the camera one frame toward its target and snaps to it on arrival (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// The current camera transition. Re-read at each use, as the C re-reads the global after calls.
inline fn transition() *v.vs_battle_cameraTransition_t {
    return v.g.vs_battle_cameraTransition().*.?;
}

/// orig: _stepCameraTransition (src/BATTLE/BATTLE.PRG/146C.c)
/// Advances the camera one step toward its transition target; on arrival it snaps to the target and returns 1, else 0.
pub fn stepCameraTransition() callconv(.c) c_int {
    const scratch = v.g.vs_scratch();
    const mask: c_int = ~@as(c_int, 0xFFF);

    const currentY: c_int = scratch.camera.position.vy & mask;
    const targetY: c_int = transition().targetPosition.vy & mask;
    const nextY: c_int = (scratch.camera.position.vy +%
        (transition().direction.vy *% transition().transitionSpeed)) & mask;

    if ((currentY >= targetY and targetY >= nextY) or
        (targetY >= currentY and nextY >= targetY))
    {
        scratch.camera.position.vx = transition().targetPosition.vx;
        scratch.camera.position.vz = transition().targetPosition.vz;
        scratch.camera.position.vy = transition().targetPosition.vy;
        scratch.camera.lookAt.vx = transition().targetLookAt.vx;
        scratch.camera.lookAt.vz = transition().targetLookAt.vz;
        scratch.camera.lookAt.vy = transition().targetLookAt.vy;

        v.g.vs_battle_cameraCurrentSpherical().* = transition().toSpherical;

        scratch.camera.farClip = transition().toFarClip;

        c.vs_battle_setNearClip(transition().toNearClip);
        c.vs_battle_setProjectionDistance(transition().toProjectionDistance);
        return 1;
    }

    scratch.camera.position.vx +%= transition().direction.vx *% transition().transitionSpeed;
    scratch.camera.position.vz +%= transition().direction.vz *% transition().transitionSpeed;
    scratch.camera.position.vy +%= transition().direction.vy *% transition().transitionSpeed;
    scratch.camera.lookAt.vx +%= transition().lookAtStep.vx;
    scratch.camera.lookAt.vz +%= transition().lookAtStep.vz;
    scratch.camera.lookAt.vy +%= transition().lookAtStep.vy;
    scratch.camera.farClip +%= transition().farClipStep;

    c.vs_battle_setNearClip(v.g.vs_main_nearClip().* +% transition().nearClipStep);
    c.vs_battle_setProjectionDistance(
        v.g.vs_main_projectionDistance().* +% transition().projectionDistanceStep,
    );

    return 0;
}
