//! zig_diff spec: vs_battle_getCurrentRoomId -> get_current_room_id.getCurrentRoomId (146C.c).
//! Inputs: the zone context's zndId and mapId, drawn from zero, -1, the i32 extremes, small
//! positives and random values. The C has no branches; the spec checks that the two ids reach
//! _getLocationId in order, unnarrowed and unnegated, and that its result is returned as is.
//! The callee is a recording stub returning any c_int.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getCurrentRoomId));

pub const classes = [_][:0]const u8{ "an-id-zero", "an-id-negative", "ids-positive" };

pub const stubs = struct {
    pub fn _getLocationId(ctx: *zd.Ctx, a: anytype, b: anytype) c_int {
        _ = a;
        _ = b;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const z = v.g._zoneContext();
    z.zndId = ctx.pick(i32, &.{ 0, -1, std.math.minInt(i32), std.math.maxInt(i32), 1, 2, 256, 65536 });
    z.mapId = ctx.pick(i32, &.{ 0, -1, std.math.minInt(i32), std.math.maxInt(i32), 1, 3, 255, 65535 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const z = v.g._zoneContext();
    if (z.zndId == 0 or z.mapId == 0) return 0;
    if (z.zndId < 0 or z.mapId < 0) return 1;
    return 2;
}
