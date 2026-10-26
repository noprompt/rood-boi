//! zig_diff spec: vs_battle_getCurrentSceneId -> get_current_scene_id.getCurrentSceneId (146C.c).
//! Inputs: vs_battle_roomData.sectionB points at a room object in the arena, whose sceneId is
//! drawn from edge values (negative, zero, positive, the i16 extremes), so the widening of the
//! signed i16 read is exercised. The C has no branches; the classes split the sign of the result.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getCurrentSceneId));

pub const classes = [_][:0]const u8{ "negative", "zero", "positive" };

/// The room prepare pointed sectionB at; classify reads its sceneId.
var room: ?*v._mpdRoomSectionB = null;

pub fn prepare(ctx: *zd.Ctx) Args {
    const r = ctx.alloc(v._mpdRoomSectionB);
    r.sceneId = ctx.pick(i16, &.{ 0, 1, -1, 2, 255, 256, 32767, -32768, -255 });
    psx.put(&v.g.vs_battle_roomData().sectionB, r);
    room = r;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const s = room.?.sceneId;
    if (@as(i32, s) < 0) return 0;
    if (s == 0) return 1;
    return 2;
}
