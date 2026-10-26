//! zig_diff spec: func_8008B6FC -> func_8008B6FC.func_8008B6FC (146C.c).
//! The unit reads one field of the room-data global and returns it. The
//! inputs set `vs_battle_roomData.section6` to edge values (0, +-1, the i32
//! extremes) and to random bits, so negative and large values are covered.
//! The other section fields are random bytes, so a port that reads a
//! neighbouring field differs. The C has no branches and no callees.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008B6FC));

pub const classes = [_][:0]const u8{ "negative", "zero", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    room.section6 = ctx.pick(i32, &.{ 0, -1, 1, std.math.maxInt(i32), std.math.minInt(i32) });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const x = v.g.vs_battle_roomData().section6;
    if (x < 0) return 0;
    if (x == 0) return 1;
    return 2;
}
