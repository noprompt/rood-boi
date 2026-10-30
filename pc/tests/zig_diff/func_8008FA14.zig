//! zig_diff spec: func_8008FA14 -> func_8008FA14.func_8008FA14 (146C.c).
//! Inputs: a random D_800F1DD4_t (the output, every field random) and a room
//! section B in the arena, wired into vs_battle_roomData.sectionB. Its base
//! values are edges (0, -1, 32767, -32768) so the i16 sums wrap on the store,
//! and its divisors are never zero (the C would trap): negative, small, and
//! large positive ones. rand() is a recording stub returning non-negative
//! values, as the C library's does.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008FA14));

pub const classes = [_][:0]const u8{ "negative-divisor", "small-divisor", "large-divisor" };

pub const stubs = struct {
    pub fn rand(ctx: *zd.Ctx) c_int {
        return @intCast(ctx.value(u31));
    }
};

var section: *v._mpdRoomSectionB = undefined;

fn divisor(ctx: *zd.Ctx) i16 {
    if (ctx.chance(3)) return ctx.edge(i16, &.{ -1, -2, -100, -32768 });
    return ctx.edge(i16, &.{ 1, 2, 3, 100, 511, 512, 513, 32767 });
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const out = ctx.alloc(v.D_800F1DD4_t);
    const b = ctx.alloc(v._mpdRoomSectionB);
    b.unk48[0].s16[0] = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });
    b.unk48[0].s16[1] = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });
    b.unk48[1].s16[0] = divisor(ctx);
    b.unk48[1].s16[1] = divisor(ctx);
    psx.put(&v.g.vs_battle_roomData().sectionB, b);
    section = b;
    return .{out};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = section.unk48[1].s16[0];
    if (d < 0) return 0;
    if (d <= 512) return 1;
    return 2;
}
