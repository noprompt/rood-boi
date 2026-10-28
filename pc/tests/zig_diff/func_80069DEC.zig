//! zig_diff spec: func_80069DEC -> func_80069DEC.func_80069DEC (146C.c).
//! Inputs: the four D_80061078 entries get random mapId and zndId values
//! from small edge sets (0, 1, 0x8000, 0xFFFF; 0, 1, 0x80, 0xFF), so matches
//! are common. The arguments are edge values (0, 1, -1, 65535, 65536, INT_MAX
//! for mapId; 0, 1, -1, 255, 256, INT_MAX for zndId), and half the time each
//! is copied from one entry k, so the match can hit any of the four slots,
//! on mapId alone, or on both. vs_main_bzero is modelled: it zeroes the
//! bytes it is given, so a dropped or resized call changes the state.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80069DEC));

pub const classes = [_][:0]const u8{ "no-map-match", "map-only", "both-match" };

pub const stubs = struct {
    pub fn vs_main_bzero(ctx: *zd.Ctx, p: anytype, n: anytype) void {
        _ = ctx;
        const len: usize = @intCast(n);
        const bytes: [*]u8 = @ptrCast(p.?);
        @memset(bytes[0..len], 0);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = v.g.D_80061078();
    for (d) |*e| {
        e.mapId = ctx.pick(u16, &.{ 0, 1, 0x8000, 0xFFFF });
        e.zndId = ctx.pick(u8, &.{ 0, 1, 0x80, 0xFF });
    }
    const k = ctx.range(usize, 0, 3);
    var mapId: c_int = ctx.edge(c_int, &.{ 0, 1, -1, 65535, 65536, 0x7FFFFFFF });
    var zndId: c_int = ctx.edge(c_int, &.{ 0, 1, -1, 255, 256, 0x7FFFFFFF });
    if (ctx.chance(2)) mapId = d[k].mapId;
    if (ctx.chance(2)) zndId = d[k].zndId;
    return .{ mapId, zndId };
}

pub fn classify(args: Args) usize {
    const d = v.g.D_80061078();
    var map_hit = false;
    for (d) |e| {
        if (@as(c_int, e.mapId) == args[0]) {
            map_hit = true;
            if (@as(c_int, e.zndId) == args[1]) return 2;
        }
    }
    return if (map_hit) 1 else 0;
}
