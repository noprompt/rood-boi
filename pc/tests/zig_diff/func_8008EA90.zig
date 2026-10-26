//! zig_diff spec: func_8008EA90 -> func_8008EA90.func_8008EA90 (146C.c).
//! Inputs: the room's sectionB pointer is null or points at an arena object
//! whose unk34 is an edge i16 (0, 1, -1, 2, the extremes; a negative value
//! shows the signed read), and arg0 is an edge c_int (0, 1, -1, the extremes,
//! so both signs of the value are tested). The callee func_80090C2C is a
//! recording stub that may rewrite the object's unk34, which the C never
//! reads back.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008EA90));

pub const classes = [_][:0]const u8{ "null-sectionB", "arg-zero", "arg-nonzero-flag-one", "arg-nonzero-other" };

var obj: *v._mpdRoomSectionB = undefined;

pub const stubs = struct {
    pub fn func_80090C2C(ctx: *zd.Ctx, arg: anytype) void {
        _ = arg;
        if (ctx.value(u1) == 1) obj.unk34 = ctx.value(i16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    obj = ctx.alloc(v._mpdRoomSectionB);
    obj.unk34 = ctx.pick(i16, &.{ 0, 1, -1, 2, 32767, -32768 });
    const p: ?*v._mpdRoomSectionB = if (ctx.chance(5)) null else obj;
    psx.put(&room.sectionB, p);
    return .{ctx.pick(c_int, &.{ 0, 1, -1, std.math.minInt(c_int), std.math.maxInt(c_int) })};
}

pub fn classify(args: Args) usize {
    const room = v.g.vs_battle_roomData();
    const b = psx.get(room.sectionB) orelse return 0;
    if (args[0] == 0) return 1;
    return if (b.unk34 == 1) 2 else 3;
}
