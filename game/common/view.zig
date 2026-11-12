//! The scene's view (vs_view, pc/src/game/include/scratch.h): the first-person/facing word, the view matrix and
//! the camera, for natives whose module has no view of it. Offsets are inside the record (0 facing, 4 matrix,
//! 0x24 camera: position, look-at, angles at 0x44, far clip at 0x54).
const psx = @import("psx.zig");

const vs_view = psx.Global([0x58]u8, "vs_view");

pub inline fn at(comptime T: type, comptime offset: usize) *T {
    return @ptrCast(@alignCast(&vs_view.ptr()[offset]));
}

pub const matrix_offset = 4;
pub const angle_offset = 0x44 + 8; // camera.angles.vz
pub const far_clip_offset = 0x54;
