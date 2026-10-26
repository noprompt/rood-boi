//! zig_diff spec: _loadMpdLootSection -> load_mpd_loot_section.loadMpdLootSection (146C.c).
//! Inputs: the room's section13 pointer is null, a guest address in PS1 RAM at
//! 0x80000000 (sign bit set; the C only takes the address of unk14, never
//! dereferences it), or an arena block. The loot source pointer is null or an
//! arena block. The memcpy stub has no memory effect and the C reads nothing
//! back after the call, so the recording behaviour is exact.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").loadMpdLootSection));

pub const classes = [_][:0]const u8{ "section13-null", "section13-low-ram", "section13-arena" };

pub const stubs = struct {
    /// The real memcpy writes dest and reads src; the C never reads either back
    /// after the call, so the stub models no memory effect. The trace checks
    /// the arguments (dest address, src, size).
    pub fn vs_main_memcpy(ctx: *zd.Ctx, dest: anytype, src: anytype, sz: anytype) void {
        _ = ctx;
        _ = dest;
        _ = src;
        _ = sz;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    // Every iteration sets section13: the globals start as random bytes, and a
    // random guest address is not a valid object.
    const sec: ?*v._mpdRoomSection13 = switch (ctx.range(u8, 0, 3)) {
        0 => null,
        1 => @ptrFromInt(0x8000_0000 + 4 * @as(usize, ctx.range(u16, 0, 0x1000))),
        else => ctx.alloc(v._mpdRoomSection13),
    };
    psx.put(&room.section13, sec);
    const data: ?*anyopaque = if (ctx.chance(4)) null else ctx.alloc(v.vs_battle_loot);
    return .{data};
}

pub fn classify(args: Args) usize {
    _ = args;
    const raw = psx.rawOf(v.g.vs_battle_roomData().section13);
    if (raw == 0) return 0;
    if (raw >= 0x8000_0000 and raw < 0x8000_8000) return 1;
    return 2;
}
