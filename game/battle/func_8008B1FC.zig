//! Battle frame camera setup: room and camera capture, view matrix, and the camera's scratchpad pointers (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008B1FC (src/BATTLE/BATTLE.PRG/146C.c)
/// Captures the room and camera for lighting, loads the view matrix from the scratchpad camera, and runs the camera passes that follow it.
pub fn func_8008B1FC(arg0: ?*anyopaque) callconv(.c) void {
    // ROOD_PC: lighting capture of world-space room geometry and this frame's camera.
    c.pc_scene_room(arg0);
    const scratch: *anyopaque = @ptrFromInt(0x1F800014);
    c.pc_scene_camera(scratch);

    const camera: *v.MATRIX = @ptrFromInt(0x1F800014);
    c.SetRotMatrix(psx.cptr(c.MATRIX, camera));
    c.SetTransMatrix(psx.cptr(c.MATRIX, camera));
    c.func_800983F8(arg0);

    // _camera.unk0: a 4-byte guest address in the scratchpad, widened to the native pointer.
    const word_a: usize = @as(usize, @as(*const u32, @ptrFromInt(0x1F800000)).*);
    const frame_a: ?*anyopaque = @ptrFromInt(word_a);
    v.g.D_800F1CC0().* = frame_a;

    c.func_8009723C(arg0, v.g.D_800F19C8().*);

    const word_b: usize = @as(usize, @as(*const u32, @ptrFromInt(0x1F800000)).*);
    const frame_b: ?*anyopaque = @ptrFromInt(word_b);
    v.g.D_800F1BB8().* = frame_b;

    if (v.g.D_800F1BB0().unk6 != 0) {
        c.func_80098D6C(v.g.D_800F1CC0().*, v.g.D_800F1BB8().*, psx.cptr(c.D_800F1BB0_t, v.g.D_800F1BB0()), 0);
    }
}
