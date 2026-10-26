//! zig_diff spec: func_8008C538 -> func_8008C538.func_8008C538 (146C.c).
//! Inputs: section 12 is absent (NULL), present with no rows, or present with
//! 1-6 rows and a random length remainder. Each row's three matrix values are
//! any i32 (negatives, INT_MIN/INT_MAX, the 4095/4096/4097 edges), so the
//! division and negation see both signs. The D_800F1CCA bank (>> 13) is below
//! 2, exactly 2, or above 2. func_8009195C returns NULL about a quarter of the
//! time, otherwise a block whose [0] and D_800F1CCA it may change (the C reads
//! both back). func_8008C6B4 may change D_800F1D68.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008C538));

pub const classes = [_][:0]const u8{ "no-section12", "no-rows", "rows-low-bank", "rows-high-bank" };

/// The block func_8009195C hands out (set by prepare).
var block: *[4]c_int = undefined;

pub const stubs = struct {
    pub fn func_8009195C(ctx: *zd.Ctx, id: anytype) [*c]c_int {
        _ = id;
        if (ctx.value(u8) < 64) return null;
        if (ctx.value(u8) < 16) block[0] = ctx.value(c_int);
        if (ctx.value(u8) < 16) v.g.D_800F1CCA().* = ctx.value(u16);
        return &block[0];
    }

    pub fn func_8008C6B4(ctx: *zd.Ctx, a: anytype, b: anytype) void {
        _ = a;
        _ = b;
        if (ctx.value(u8) < 64) v.g.D_800F1D68().* = ctx.value(i16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    v.g.D_800F1CCA().* = ctx.pick(u16, &.{ 0, 0x2000, 0x3FFF, 0x4000, 0x5FFF, 0x6000, 0xFFFF });
    block = @ptrCast(@alignCast(ctx.allocBytes(16, 16)));

    if (ctx.chance(5)) {
        // Absent section: the C must not dereference it, so the length is free.
        psx.put(&room.section12, @as(?*v._mpdRoomSection12, null));
        room.header.section12Len = ctx.int(u32);
        return .{};
    }

    const count = ctx.range(u32, 0, 6);
    const rows: [*]v._mpdRoomSection12 = @ptrCast(@alignCast(ctx.allocBytes((count + 1) * @sizeOf(v._mpdRoomSection12), 16)));
    room.header.section12Len = count * 184 + ctx.range(u32, 0, 183);
    psx.put(&room.section12, &rows[0]);

    const edges = [_]i32{ 0, 4095, 4096, 4097, -1, -4095, -4096, -4097, std.math.minInt(i32), std.math.maxInt(i32) };
    for (0..count + 1) |i| {
        rows[i].unkA8 = ctx.pick(i32, &edges);
        rows[i].unkAC = ctx.pick(i32, &edges);
        rows[i].unkB0 = ctx.pick(i32, &edges);
    }
    return .{};
}

pub fn classify(_: Args) usize {
    const room = v.g.vs_battle_roomData();
    if (psx.get(room.section12) == null) return 0;
    if (room.header.section12Len / 184 == 0) return 1;
    return if ((v.g.D_800F1CCA().* >> 13) >= 2) 3 else 2;
}
