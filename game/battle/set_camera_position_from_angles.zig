//! Places the battle camera from its spherical angles (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _setCameraPositionFromAngles (src/BATTLE/BATTLE.PRG/146C.c)
/// Computes the camera position from its spherical angles about its look-at point; the right-stick zoom applies to a copy of the battle camera's values.
pub fn setCameraPositionFromAngles(spherical: ?*v._sphericalValues) callconv(.c) void {
    // ROOD_PC: right-stick camera (pc/src/camera_stick.c) places a copy of the follow camera's values.
    const Hook = *const fn (?*anyopaque, ?*const anyopaque) callconv(.c) void;
    var current = spherical;
    var placed: v._sphericalValues = undefined;
    if (psx.weak(Hook, "pc_camera_stick_place")) |place| {
        if (spherical == &v.g.vs_battle_cameraCurrentSpherical().values) {
            placed = spherical.?.*;
            place(&placed, &v.g.vs_scratch().camera.lookAt);
            current = &placed;
        }
    }

    c._computeSphericalOffset(
        psx.cptr(c.VECTOR, &v.g.vs_scratch().camera.position),
        psx.cptr(c.VECTOR, &v.g.vs_scratch().camera.lookAt),
        @ptrCast(current),
    );
}
