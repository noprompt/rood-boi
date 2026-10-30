//! zig_diff spec: func_8008D3E8 -> func_8008D3E8.func_8008D3E8 (146C.c).
//! The C has no branches: it reads the global vs_battle_roomData.sectionB (a
//! 4-byte guest pointer), follows it and returns the byte at unk31. The inputs
//! point sectionB at a fresh arena object whose unk31 is an edge value (0, 1,
//! 127, 128, 255, or any byte), so the classes split on its high bit. The
//! non-null pointer is always valid, because the C does not test it.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008D3E8));

pub const classes = [_][:0]const u8{ "bit7-clear", "bit7-set" };

var cur: *v._mpdRoomSectionB = undefined;

pub fn prepare(ctx: *zd.Ctx) Args {
    const b = ctx.alloc(v._mpdRoomSectionB);
    b.unk31 = ctx.pick(u8, &.{ 0, 1, 127, 128, 255 });
    b.trapLevel = ctx.int(u8);
    b.isWorkshop = ctx.int(u8);
    psx.put(&v.g.vs_battle_roomData().sectionB, b);
    cur = b;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (cur.unk31 & 0x80 == 0) 0 else 1;
}
