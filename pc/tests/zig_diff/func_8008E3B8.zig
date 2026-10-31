//! zig_diff spec: func_8008E3B8 -> func_8008E3B8.func_8008E3B8 (146C.c).
//! Inputs: the room's section A pointer is null, a high guest address (the C
//! only takes its sizeof and returns it, so it is never dereferenced), or an
//! arena block. The section A length sits at the element-size edges, 0 and the
//! 32-bit extremes. The out cell arg0 is an arena int.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
const psx = @import("common").psx;
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008E3B8));

pub const classes = [_][:0]const u8{ "null", "high-raw", "len-zero", "nonzero" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const root = v.g.vs_battle_roomData();
    const elem = @sizeOf(v._mpdRoomSectionA);
    const blk = ctx.alloc(v._mpdRoomSectionA);
    const out = ctx.alloc(c_int);

    const kind = ctx.range(u8, 0, 7);
    if (kind < 2) {
        root.sectionA.raw = 0;
    } else if (kind == 2) {
        root.sectionA.raw = 0x8000_0000 | ctx.range(u32, 0, 0x7FFF_FFFF);
    } else {
        psx.put(&root.sectionA, blk);
    }

    root.header.sectionALen = ctx.pick(u32, &.{ 0, 1, elem - 1, elem, elem + 1, 0xFFFF_FFFF, 0x8000_0000 });
    return .{out};
}

pub fn classify(args: Args) usize {
    _ = args;
    const root = v.g.vs_battle_roomData();
    if (root.sectionA.raw == 0) return 0;
    if ((root.sectionA.raw & 0x8000_0000) != 0) return 1;
    if (root.header.sectionALen == 0) return 2;
    return 3;
}
