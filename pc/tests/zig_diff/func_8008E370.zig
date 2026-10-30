//! zig_diff spec: func_8008E370 -> func_8008E370.func_8008E370 (146C.c).
//! Inputs: section13 is null or a non-null raw guest address with the sign bit
//! set or clear. The C never dereferences that pointer; it only reads its value
//! back, so the addresses need not be valid memory (they stay even, so the
//! struct pointer is aligned). The header's section13Len takes 0, 1, 2, 3, the
//! unsigned edges 0x7FFFFFFF, 0x80000000 and 0xFFFFFFFF, and random values (the
//! division is unsigned). The out-parameter is a fresh arena int, so the null
//! path's store of 0 is compared against the random fill.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008E370));

pub const classes = [_][:0]const u8{ "null-section13", "section13-high-bit", "section13-low-bit" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    const out: [*c]c_int = @ptrCast(ctx.alloc(c_int));
    room.header.section13Len = ctx.pick(u32, &.{ 0, 1, 2, 3, 0x7FFF_FFFF, 0x8000_0000, 0xFFFF_FFFF });
    var p: ?*v._mpdRoomSection13 = null;
    if (!ctx.chance(4)) {
        var raw: u32 = if (ctx.chance(2))
            ctx.edge(u32, &.{ 0x8000_0000, 0x7FFF_FFFE, 0xFFFF_FFFE, 0x8000_0002 })
        else
            ctx.int(u32) & ~@as(u32, 1);
        if (raw == 0) raw = 2;
        p = @ptrFromInt(raw);
    }
    psx.put(&room.section13, p);
    return .{out};
}

pub fn classify(args: Args) usize {
    _ = args;
    const room = v.g.vs_battle_roomData();
    const raw = psx.rawOf(room.section13);
    if (raw == 0) return 0;
    if ((raw & 0x8000_0000) != 0) return 1;
    return 2;
}
