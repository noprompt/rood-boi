//! zig_diff spec: func_8008BAC8 -> func_8008BAC8.func_8008BAC8 (146C.c).
//! Inputs: the room's door section is null or an arena array of 0-6 real
//! 12-byte door entries (its length is that count times 12, plus a remainder
//! of 0-11, so the loop count is the count), whose 5-bit and 3-bit fields are
//! drawn from edge sets so the match tests hit both sides. The three arguments
//! are edge values half the time and the fields of one entry the other half,
//! so full matches, first-disjunct matches (arg2 >= 2), and misses all occur.
//! arg2 == 2 is common, giving the `arg2 >= 2` compare its equal sides.
//! The rand() stub returns any int, so the truncating store to unkAC[7] is tested.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008BAC8));

pub const classes = [_][:0]const u8{ "no-door", "no-entries", "matched", "unmatched" };

pub const stubs = struct {
    // rand() is a plain int stub: its value is stored (truncated) in unkAC[7].
    pub fn rand(ctx: *zd.Ctx) c_int {
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();

    // Eight door entries of 12 bytes each; the C reads at most six of them.
    const door: [*]v._mpdRoomDoorSection_t = @ptrCast(ctx.allocBytes(12 * 8, 4));
    for (0..8) |i| {
        const e = &door[i];
        psx.setBits(&e.unk2, "unk0_0", ctx.pick(u5, &.{ 0, 1, 31 }));
        psx.setBits(&e.unk2, "unk0_5", ctx.pick(u5, &.{ 0, 1, 31 }));
        psx.setBits(&e.unk2, "unk0_10", ctx.pick(u3, &.{ 0, 1, 2, 7 }));
    }

    const n: usize = ctx.range(usize, 0, 6);
    const rem: u32 = ctx.range(u32, 0, 11);
    psx.put(&room.doorSection, if (ctx.chance(8)) null else &door[0]);
    room.header.doorSectionLen = @as(u32, @intCast(n * 12)) + rem;

    const src = &door[ctx.range(usize, 0, 7)];
    var arg0: c_int = ctx.pick(c_int, &.{ 0, 1, 31, 32, -1 });
    var arg1: c_int = ctx.pick(c_int, &.{ 0, 1, 31, 32, -1 });
    var arg2: c_int = ctx.pick(c_int, &.{ 0, 1, 2, 3, 7, 8, -1 });
    if (ctx.chance(2)) {
        arg0 = @intCast(psx.getBits(&src.unk2, "unk0_0"));
        arg1 = @intCast(psx.getBits(&src.unk2, "unk0_5"));
        arg2 = @intCast(psx.getBits(&src.unk2, "unk0_10"));
    }
    return .{ arg0, arg1, arg2 };
}

pub fn classify(args: Args) usize {
    const room = v.g.vs_battle_roomData();
    const door = psx.get(room.doorSection) orelse return 0;
    const n = room.header.doorSectionLen / 12;
    if (n == 0) return 1;
    const base: [*]v._mpdRoomDoorSection_t = @ptrCast(door);
    var i: u32 = 0;
    while (i < n) : (i += 1) {
        const e = &base[i];
        const f0 = @as(c_int, psx.getBits(&e.unk2, "unk0_0"));
        const f1 = @as(c_int, psx.getBits(&e.unk2, "unk0_5"));
        const f2 = @as(c_int, psx.getBits(&e.unk2, "unk0_10"));
        const hit = (args[2] >= 2 and f2 == args[2]) or
            (f0 == args[0] and f1 == args[1] and f2 == args[2]);
        if (hit) return 2;
    }
    return 3;
}
