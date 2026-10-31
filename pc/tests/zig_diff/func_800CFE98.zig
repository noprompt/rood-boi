//! zig_diff spec: func_800CFE98 -> func_800CFE98.func_800CFE98 (5BF94.c).
//! Inputs: a random func_800CFE98_t (the destination) and an SVECTOR source whose
//! fields are edge values (0, -1, 1, the i16 extremes) or random. The source is
//! either a separate arena object or the destination's own unk14 (the aliased
//! class), so a store that lands before the call is read back by the copy.
//! func_800CFE7C is a recording stub that rewrites random fields of the
//! destination, as the real callee may, so a port that drops the call, moves
//! the stores across it, or reads the source before the call fails.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
const psx = @import("common").psx;
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CFE98));

pub const classes = [_][:0]const u8{ "distinct", "aliased" };

pub const stubs = struct {
    /// Rewrites random fields of the destination, as the real callee may.
    pub fn func_800CFE7C(ctx: *zd.Ctx, p: anytype) void {
        const a: *v.func_800CFE98_t = @ptrCast(@alignCast(p));
        if (ctx.value(u1) == 1) a.unk0 = ctx.value(i32);
        if (ctx.value(u1) == 1) a.unk4 = ctx.value(i32);
        if (ctx.value(u1) == 1) a.unk14.vx = ctx.value(i32);
        if (ctx.value(u1) == 1) a.unk14.vy = ctx.value(i32);
        if (ctx.value(u1) == 1) a.unk14.vz = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const dst = ctx.alloc(v.func_800CFE98_t);
    const src: *v.SVECTOR = if (ctx.chance(4))
        @ptrCast(@alignCast(&dst.unk14))
    else
        ctx.alloc(v.SVECTOR);
    src.vx = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });
    src.vy = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });
    src.vz = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });
    return .{ src, dst };
}

pub fn classify(args: Args) usize {
    const src = args[0].?;
    const dst = args[1].?;
    return if (@intFromPtr(src) == @intFromPtr(&dst.unk14)) 1 else 0;
}
