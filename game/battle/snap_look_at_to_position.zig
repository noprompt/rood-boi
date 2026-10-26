//! Moves the camera's look-at point toward a zone-clamped position, stepping each axis by a bounded amount (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _snapLookAtToPosition (src/BATTLE/BATTLE.PRG/146C.c)
/// Snaps the camera look-at toward a zone-clamped position, at most 0x12000 per horizontal axis and 0x60000 vertically.
pub fn snapLookAtToPosition(position: ?*v.VECTOR) callconv(.c) void {
    var sp10: v.func_80077DF0_t = undefined;
    // 0xFFFEE000 and 0xFFFA0000 as C's int (new_var).
    const limit_x: c_int = -0x12000;
    const limit_y: c_int = -0x60000;

    // A NULL position is passed through unchanged, as the C does.
    const position_c: [*c]c.VECTOR = @ptrCast(position);
    c._clampPositionToZoneBounds(position_c, psx.cptr(c.VECTOR, &sp10.position));

    const scratch = v.g.vs_scratch();
    sp10.lookAt.vx = sp10.position.vx -% scratch.camera.lookAt.vx;
    sp10.lookAt.vz = sp10.position.vz -% scratch.camera.lookAt.vz;
    sp10.lookAt.vy = sp10.position.vy -% scratch.camera.lookAt.vy;

    if (sp10.lookAt.vx > 0x12000) {
        scratch.camera.lookAt.vx +%= 0x12000;
    } else if (sp10.lookAt.vx < limit_x) {
        scratch.camera.lookAt.vx -%= 0x12000;
    } else {
        scratch.camera.lookAt.vx = sp10.position.vx;
    }

    if (sp10.lookAt.vz > 0x12000) {
        scratch.camera.lookAt.vz +%= 0x12000;
    } else if (sp10.lookAt.vz < limit_x) {
        scratch.camera.lookAt.vz -%= 0x12000;
    } else {
        scratch.camera.lookAt.vz = sp10.position.vz;
    }

    if (sp10.lookAt.vy < 0) {
        if (sp10.lookAt.vy < limit_y) {
            scratch.camera.lookAt.vy +%= 0x60000 +% sp10.lookAt.vy;
        }
    } else if (sp10.lookAt.vy > 0x60000) {
        scratch.camera.lookAt.vy -%= 0x60000 -% sp10.lookAt.vy;
    }

    if (scratch.camera.lookAt.vy > 0) {
        scratch.camera.lookAt.vy = 0;
    }
}
