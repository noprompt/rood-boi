//! Sets up the battle camera from its spherical position and resets its angles
//! (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80077EC4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Initialises the scratchpad camera from its spherical position, sets the far clip to 0x1000 and zeroes its angles.
pub fn func_80077EC4() callconv(.c) void {
    const scratch = v.g.vs_scratch();
    c.vs_battle_initialiseCameraFromSpherical(
        psx.cptr(c.VECTOR, &scratch.camera.position),
        psx.cptr(c.VECTOR, &scratch.camera.lookAt),
        -1,
        -1,
    );
    scratch.camera.farClip = 0x1000;
    scratch.camera.angles.vz = 0;
    scratch.camera.angles.vy = 0;
    scratch.camera.angles.vx = 0;
}
