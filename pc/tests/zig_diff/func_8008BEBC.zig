//! zig_diff spec: func_8008BEBC -> func_8008BEBC.func_8008BEBC (146C.c).
//! Inputs: one _mpdRoomSectionA in the arena, always non-null (the C dereferences
//! it unchecked). unk12 is 0 most runs (the work path), otherwise 1, 2, 0x7F,
//! 0x80 or 0xFF (the early return). keyOrSigil is drawn from the edges around
//! 0x1CA..0x1D1 (the range test's bounds and its equal-to-7 side), with -1 and
//! -32310 (0x81CA) so that a signed read differs from the C's u16 read. unkE is
//! 0 about half the time and otherwise 1, -1, 0x7FFF or -32768. The callees
//! write the object's unk10 and unkE the way the real ones may, and return
//! ctx.value results (the C ignores the return of func_8008BF48).
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008BEBC));

pub const classes = [_][:0]const u8{
    "already-set",
    "in-range-unkE0",
    "in-range-unkE",
    "out-range-unkE0",
    "out-range-unkE",
};

pub const stubs = struct {
    pub fn func_8008C070(ctx: *zd.Ctx, arg0: c_int, arg1: anytype) void {
        _ = arg0;
        const a: *v._mpdRoomSectionA = @ptrCast(@alignCast(arg1));
        if (ctx.value(u1) == 1) a.unk10 = ctx.value(i16);
    }

    pub fn func_8008BF48(ctx: *zd.Ctx, arg0: anytype) c_int {
        const a: *v._mpdRoomSectionA = @ptrCast(@alignCast(arg0));
        if (ctx.value(u1) == 1) a.unkE = ctx.value(i16);
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const a = ctx.alloc(v._mpdRoomSectionA);
    a.unk12 = if (ctx.chance(5)) ctx.edge(u8, &.{ 1, 2, 0x7F, 0x80, 0xFF }) else 0;
    a.keyOrSigil = ctx.pick(i16, &.{ 0x1C9, 0x1CA, 0x1CB, 0x1D0, 0x1D1, 0x1D2, 0, -1, -32310, 0x7FFF, -32768 });
    a.unkE = if (ctx.chance(2)) 0 else ctx.pick(i16, &.{ 1, -1, 0x7FFF, -32768 });
    return .{a};
}

pub fn classify(args: Args) usize {
    const a = args[0].?;
    if (a.unk12 != 0) return 0;
    const t: u16 = @bitCast(a.keyOrSigil);
    const in_range = (t -% 0x1CA) < 7;
    if (in_range) return if (a.unkE == 0) 1 else 2;
    return if (a.unkE == 0) 3 else 4;
}
