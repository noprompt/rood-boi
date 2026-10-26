//! zig_diff spec: func_8008E4AC -> func_8008E4AC.func_8008E4AC (146C.c).
//! Inputs: vs_battle_roomData.sectionB points at an arena _mpdRoomSectionB
//! whose unk56 is an edge value (0, 1, -1, the i16 extremes) or random bytes.
//! The C has no branches and no comparisons. Its only risks are the field
//! read, the sign of the i16 result and the wrap of unk56 + 1, so the classes
//! split on the sign of unk56 and the edges catch signed and off-by-one slips.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008E4AC));

pub const classes = [_][:0]const u8{ "negative", "zero", "positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    const b = ctx.alloc(v._mpdRoomSectionB);
    psx.put(&room.sectionB, b);
    // Edges half the time; random bytes (any i16) otherwise.
    b.unk56 = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 255, 256 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    // psx.get on a psx.Ptr field yields an optional; the prepare above made it non-null.
    const b = psx.get(v.g.vs_battle_roomData().sectionB).?;
    if (b.unk56 < 0) return 0;
    if (b.unk56 == 0) return 1;
    return 2;
}
