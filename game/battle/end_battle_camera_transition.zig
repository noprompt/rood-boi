//! Ends a battle camera transition: restores the camera it started from, frees the transition and resets the camera subsystems (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _endBattleCameraTransition (src/BATTLE/BATTLE.PRG/146C.c)
/// Restores the camera a transition started from, frees the transition and resets the camera subsystems.
pub fn endBattleCameraTransition() callconv(.c) void {
    v.g.vs_scratch().camera = v.g.vs_battle_cameraTransition().*.?.fromCameraState;

    v.g.vs_battle_cameraCurrentSpherical().* = v.g.vs_battle_cameraTransition().*.?.fromSpherical;

    v.g.vs_battle_cameraCurrentSpherical().delta.pitch = v.g.vs_battle_cameraCurrentSpherical().values.yaw;
    c.vs_battle_setNearClip(v.g.vs_battle_cameraTransition().*.?.fromNearClip);
    c.vs_battle_setProjectionDistance(v.g.vs_battle_cameraTransition().*.?.fromProjectionDistance);

    if (v.g.vs_battle_cameraTransition().*) |transition| {
        c.vs_main_freeHeapR(transition);
        v.g.vs_battle_cameraTransition().* = null;
    }

    c.func_800CB654(0);
    _ = c.func_8008B4C8(1);
    c.func_8008D594(0);
    c.func_80095B70(0);
    _ = c.func_800A0870(0);
    c.func_8006F5CC();
}
