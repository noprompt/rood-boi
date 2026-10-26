//! zig_diff spec: _setRoomSeen -> set_room_seen.setRoomSeen (146C.c).
//! Inputs: the pending flag D_800F19A0 is clear about one run in four and
//! otherwise a random i32 (1, -1, 2, the i32 extremes, or any value), so both
//! the early return and the update run, with the flag's sign bit both set and
//! clear. The two ID stubs return in-range IDs (scene 0..63 for areaFlags, room
//! 0..511 for roomFlags) covering every bit position. The area and room words
//! keep their random fill, so the `|=` is checked against prior bits.
const std = @import("std");
const zd = @import("zdiff");
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").setRoomSeen));

pub const classes = [_][:0]const u8{ "flag-clear", "flag-set" };

pub const stubs = struct {
    pub fn vs_battle_getCurrentSceneId(ctx: *zd.Ctx) c_int {
        return @as(c_int, ctx.value(u8) & 63);
    }

    pub fn vs_battle_getCurrentRoomId(ctx: *zd.Ctx) c_int {
        return @as(c_int, ctx.value(u16) % 512);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const flag = v.g.D_800F19A0();
    if (ctx.chance(4)) {
        flag.* = 0;
    } else {
        flag.* = ctx.pick(i32, &.{ 1, -1, 2, std.math.minInt(i32), std.math.maxInt(i32) });
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F19A0().* == 0) 0 else 1;
}
