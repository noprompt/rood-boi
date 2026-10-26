//! zig_diff spec: func_8007C4E0 -> func_8007C4E0.func_8007C4E0 (146C.c).
//! The C is straight-line code: no branches and no ordered comparisons, so the
//! inputs cover its data flow. arg0 is a valid section (the C dereferences it
//! unconditionally, so it is never null): usually a fresh arena object with
//! random fields and mpdId/zndId at edges, sometimes D_800F1AB0 itself (the
//! struct copy aliases its destination). effect and speed take sign and
//! extreme edges. The callees write the globals the C does not read back
//! after the call (_zoneContext.zndId, the transition step and speed), so a
//! port that re-reads or re-stores them across a call differs.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C4E0));

pub const classes = [_][:0]const u8{ "arena-section", "aliases-D_800F1AB0" };

pub const stubs = struct {
    pub fn _loadMpd(ctx: *zd.Ctx, arg0: anytype) void {
        _ = arg0;
        if (ctx.value(u1) == 1) v.g._zoneContext().zndId = ctx.value(i32);
    }

    pub fn func_8009E5C4(ctx: *zd.Ctx, arg0: anytype) void {
        _ = arg0;
        v.g.vs_battle_screenTransitionStep().* = ctx.value(u32);
    }

    pub fn func_800A0A1C(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) void {
        _ = arg0;
        _ = arg1;
        v.g.vs_battle_screenTransitionSpeed().* = ctx.value(i32);
    }

    pub fn func_8008B8F8(ctx: *zd.Ctx, arg0: anytype) void {
        _ = ctx;
        _ = arg0;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const section = ctx.alloc(v._mpdRoomDoorSection_t);
    section.mpdId = ctx.pick(u8, &.{ 0, 1, 127, 128, 255 });
    section.zndId = ctx.pick(u8, &.{ 0, 1, 255 });
    const effect = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000 });
    const speed = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000 });
    if (ctx.chance(8)) return .{ v.g.D_800F1AB0(), effect, speed };
    return .{ section, effect, speed };
}

pub fn classify(args: Args) usize {
    return if (args[0].? == v.g.D_800F1AB0()) 1 else 0;
}
