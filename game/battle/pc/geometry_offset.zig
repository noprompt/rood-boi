//! GTE screen offset access (D2: 2EA3C.s; oracle pc/src/room_geometry.c).
const gte = @import("common").gte;

/// orig: vs_battle_getGeomOffset (pc/src/room_geometry.c)
/// Reads the GTE screen offset (OFX/OFY, 16.16) as two integers.
pub fn getGeomOffset(offset: [*]c_uint) callconv(.c) void {
    const screen = gte.screenCurrent();
    offset[0] = @as(c_uint, @bitCast(screen.ofx)) >> 16;
    offset[1] = @as(c_uint, @bitCast(screen.ofy)) >> 16;
}

/// orig: vs_battle_setGeomOffset (pc/src/room_geometry.c)
/// Writes the GTE screen offset (OFX/OFY) from two integers.
pub fn setGeomOffset(offset: [*]const c_uint) callconv(.c) void {
    gte.setGeomOffset(@bitCast(offset[0]), @bitCast(offset[1]));
}
