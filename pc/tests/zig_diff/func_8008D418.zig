//! zig_diff spec: func_8008D418 -> func_8008D418.func_8008D418 (146C.c).
//! Inputs: vs_battle_roomData.sectionB points at a _mpdRoomSectionB in the
//! arena, with unk52 and unk54 drawn from edges that cover zero, -1, the
//! i16 extremes, and values with and without the sign bit. The C has no
//! branches and no calls, so the classes split only by the signs of the two
//! halfwords, which decide how the OR and the sign extension combine.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008D418));

pub const classes = [_][:0]const u8{ "unk52-negative", "unk54-negative", "both-nonnegative" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    const sec = ctx.alloc(v._mpdRoomSectionB);
    sec.unk52 = ctx.pick(i16, &.{ 0, 1, -1, 0x7FFF, -32768, 0x100, -0x100, 0x4000 });
    sec.unk54 = ctx.pick(i16, &.{ 0, 1, -1, 0x7FFF, -32768, 0x100, -0x100, 0x4000 });
    psx.put(&room.sectionB, sec);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const sec = psx.get(v.g.vs_battle_roomData().sectionB).?;
    if (sec.unk52 < 0) return 0;
    if (sec.unk54 < 0) return 1;
    return 2;
}
