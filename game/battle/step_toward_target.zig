//! Camera look-at stepping toward a target position (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _stepTowardTarget (src/BATTLE/BATTLE.PRG/146C.c)
/// Moves the camera's look-at point one step toward a target position and returns the camera speed.
pub fn stepTowardTarget(targetPos: ?*v.SVECTOR, transformFlag: c_int, maxSpeed: c_int) callconv(.c) c_int {
    var displacement: v.VECTOR = undefined;
    var step: v.VECTOR = undefined;
    const scratch = v.g.vs_scratch();
    const lookAt = &scratch.camera.lookAt;

    if (c._computeStepAndDisplacement(
        @ptrCast(targetPos),
        @ptrCast(&step),
        @ptrCast(&displacement),
        transformFlag,
        maxSpeed,
    ) != 0) {
        lookAt.vx = c._addMinDelta(lookAt.vx, step.vx, displacement.vx);
        lookAt.vz = c._addMinDelta(lookAt.vz, step.vz, displacement.vz);
        lookAt.vy = c._addMinDelta(lookAt.vy, step.vy, displacement.vy);
    } else {
        lookAt.vx = c._add_min(lookAt.vx, step.vx, displacement.vx);
        lookAt.vz = c._add_min(lookAt.vz, step.vz, displacement.vz);
        lookAt.vy = c._add_min(lookAt.vy, step.vy, displacement.vy);
    }
    if (lookAt.vy > 0) {
        lookAt.vy = 0;
    }
    return v.g.vs_battle_cameraCurrentSpherical().speed;
}
