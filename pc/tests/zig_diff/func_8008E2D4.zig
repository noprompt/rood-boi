//! zig_diff spec: func_8008E2D4 -> func_8008E2D4.func_8008E2D4 (146C.c).
//! Inputs: vs_battle_roomData.section12 is either NULL or the middle of a
//! 32 KB arena block of random room section 12 records. arg0 is one of a few
//! small indices, including negatives, which reach records before the base
//! (still inside the arena). The addressed record's unk0_27 bitfield is
//! randomised over its full 2-bit range, so the `* 16` term and the pointer
//! arithmetic both show up in the returned address.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008E2D4));

pub const classes = [_][:0]const u8{ "null-section", "negative-index", "nonnegative-index" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const roomData = v.g.vs_battle_roomData();
    // 16 KB of room behind and after the base: indices -8..8 stay inside it.
    const blk = ctx.allocBytes(32768, 16);
    const base: *v._mpdRoomSection12 = @ptrCast(@alignCast(blk + 16384));
    const idx = ctx.edge(c_int, &.{ -8, -3, -2, -1, 0, 1, 2, 3, 7, 8 });

    // Any record the C may address gets a random 2-bit unk0_27.
    const elem = psx.at(base, idx);
    psx.setBits(elem, "unk0_27", ctx.int(u2));

    psx.put(&roomData.section12, if (ctx.chance(6)) null else base);
    return .{idx};
}

pub fn classify(args: Args) usize {
    if (psx.get(v.g.vs_battle_roomData().section12) == null) return 0;
    return if (args[0] < 0) 1 else 2;
}
