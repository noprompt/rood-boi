//! zig_diff spec: func_8008C6B4 -> func_8008C6B4.func_8008C6B4 (146C.c).
//! Inputs: the room's section12 pointer is null or points at an 8-entry arena
//! array, and the spec's entry `target` is element arg0 (arg0 from -2 to 5, so
//! the C indexes in-range entries of the array). The entry's vectors take
//! division edges (+-4095, +-4096, +-4097, the i32 extremes). arg1 covers
//! -2, -1 (reload from unk4_8), 0 (the `arg1 >= 0` sides equal), small
//! positives, and any int (truncated into 2-bit fields). The callee
//! func_8009195C returns NULL about a fifth of the time, and otherwise a valid
//! buffer. It also overwrites unkA8/unkAC/unkB0 of `target` in some calls, which
//! the C re-reads after the call.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008C6B4));

pub const classes = [_][:0]const u8{ "no-section", "below-minus-one", "minus-one", "zero", "positive" };

/// The section entry the C works on (set by prepare, written by the stub).
var target: *v._mpdRoomSection12 = undefined;
var no_section = false;

pub const stubs = struct {
    pub fn func_8009195C(ctx: *zd.Ctx, p: anytype) [*c]c_int {
        _ = p;
        // Writes first, so the C re-reads them whether or not it gets a buffer.
        if (ctx.value(u2) != 0) target.unkA8 = ctx.value(i32);
        if (ctx.value(u2) != 0) target.unkAC = ctx.value(i32);
        if (ctx.value(u2) != 0) target.unkB0 = ctx.value(i32);
        if (ctx.value(u8) < 48) return null; // the C's NULL test
        const buf: [*]c_int = @ptrCast(@alignCast(ctx.allocBytes(16, 4)));
        return buf;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const base: [*]v._mpdRoomSection12 = @ptrCast(@alignCast(ctx.allocBytes(@sizeOf(v._mpdRoomSection12) * 8, 16)));
    const arg0 = ctx.range(c_int, -2, 5);
    target = &base[@intCast(arg0 + 2)];

    const section = v.g.vs_battle_roomData();
    no_section = ctx.chance(6);
    if (no_section) {
        const none: ?*v._mpdRoomSection12 = null;
        psx.put(&section.section12, none);
    } else {
        psx.put(&section.section12, &base[2]);
    }

    const edges = [_]i32{ -4097, -4096, -4095, -1, 0, 1, 4095, 4096, 4097, std.math.maxInt(i32), std.math.minInt(i32) };
    for (&target.unk8) |*vec| {
        vec.vx = ctx.pick(i32, &edges);
        vec.vy = ctx.pick(i32, &edges);
        vec.vz = ctx.pick(i32, &edges);
    }
    // unk0_14 is arg1 & 3 after the C's store: equal to unk0_10 about a quarter of the time.
    psx.setBits(target, "unk0_10", ctx.int(u2));

    const arg1 = ctx.pick(c_int, &.{ -1, -1, -2, 0, 0, 1, 2, 3, 4, 7, -0x8000_0000, 0x7fff_ffff });
    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    if (no_section) return 0;
    const arg1 = args[1];
    if (arg1 < -1) return 1;
    if (arg1 == -1) return 2;
    if (arg1 == 0) return 3;
    return 4;
}
