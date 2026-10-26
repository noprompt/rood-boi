//! zig_diff spec: _getMapBounds -> get_map_bounds.getMapBounds (146C.c).
//! Inputs: the argument (any int) and vs_battle_roomData.section18, the
//! guest pointer the C tests and returns. Three classes: the field is 0
//! (the C returns NULL), the field points at a bounds block in the arena,
//! or the field holds the PS1 address of low RAM (0x80000000, sign bit set).
//! The C only tests the pointer against NULL and returns it, so nothing is
//! dereferenced; the arena and low-RAM targets are both valid memory.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getMapBounds));

pub const classes = [_][:0]const u8{ "null", "arena-bounds", "low-ram-sign-bit" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const bounds = ctx.alloc(v._zoneContextBounds);
    bounds.minX = ctx.int(i16);
    bounds.minZ = ctx.int(i16);
    bounds.maxX = ctx.int(i16);
    bounds.maxZ = ctx.int(i16);

    const room = v.g.vs_battle_roomData();
    const mode = ctx.range(u8, 0, 2);
    switch (mode) {
        0 => psx.put(&room.section18, @as(?*v._zoneContextBounds, null)),
        1 => psx.put(&room.section18, bounds),
        else => psx.put(&room.section18, psx.lowRam(v._zoneContextBounds)),
    }
    return .{ctx.pick(c_int, &.{ 0, -1, 1, 0x7FFF_FFFF, -0x8000_0000 })};
}

pub fn classify(args: Args) usize {
    _ = args;
    const room = v.g.vs_battle_roomData();
    const raw = psx.rawOf(room.section18);
    if (raw == 0) return 0;
    if (raw == 0x8000_0000) return 2;
    return 1;
}
