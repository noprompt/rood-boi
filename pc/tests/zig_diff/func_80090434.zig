//! zig_diff spec: func_80090434 -> func_80090434.func_80090434 (146C.c).
//! Inputs: the scratchpad's two pointers into the arena (a cursor buffer for
//! the tiles and an ordering table), up to 6 particles in the arena, and the
//! globals that pick the mode: BA4 zero (particles update) or not (they hold),
//! DC7 at its edges (0, 32, 95, 96, 97, 255), DC0 at or below zero, and
//! tickspeed from -1 to 5. Particles are random or on their bounds. A quarter
//! of the runs pin particle 0 to the exact boundary: unk4 = 256 makes the
//! divisor 4096, so x and y equal unk0 and unk2 (319 and 239 there), and unk8
//! and unkA are 319 and 239, so both `<` compares see their sides equal. unk4
//! is never -768 (the C divides by unk4*4+3072). RotTrans writes origin and
//! velocity (zero half the time, so the origin is zero about a quarter of the
//! time), and rsin and rcos return 0 a quarter of the time so updates can leave
//! the bounds unchanged. rand returns any 32-bit value.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80090434));

pub const classes = [_][:0]const u8{ "no-particles", "update", "hold", "boundary" };

pub const stubs = struct {
    pub fn RotTrans(ctx: *zd.Ctx, v0: anytype, v1: anytype, flag: anytype) void {
        _ = v0;
        const out: *v.VECTOR = @ptrCast(@alignCast(v1));
        const zero = ctx.value(u1) == 1;
        out.vx = if (zero) 0 else ctx.value(i16);
        out.vy = if (zero) 0 else ctx.value(i16);
        out.vz = if (zero) 0 else ctx.value(i16);
        out.pad = ctx.value(i32);
        const f: *c_int = @ptrCast(@alignCast(flag));
        f.* = ctx.value(c_int);
    }

    pub fn rsin(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        if (ctx.value(u2) == 0) return 0;
        return ctx.value(i16);
    }

    pub fn rcos(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        if (ctx.value(u2) == 0) return 0;
        return ctx.value(i16);
    }

    pub fn rand(ctx: *zd.Ctx) c_int {
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const scratch: *v.vs_scratch_t = @ptrFromInt(zd.scratchpad);
    const cursor: *anyopaque = @ptrCast(ctx.allocBytes(512, 16));
    const ot: *anyopaque = @ptrCast(ctx.allocBytes(64, 16));
    psx.put(&scratch.unk0, cursor);
    psx.put(&scratch.unk4, ot);

    const parts: *[6]v.D_800F1DD4_t = @ptrCast(@alignCast(ctx.allocBytes(@sizeOf(v.D_800F1DD4_t) * 6, 16)));
    for (parts) |*p| {
        p.unkD = ctx.edge(u8, &.{ 0, 1, 31, 32, 33, 255 });
        if (ctx.chance(3)) {
            p.unk0 = ctx.edge(i16, &.{ 0, 320, 280 });
            p.unk2 = ctx.edge(i16, &.{ 0, 240, 210 });
            p.unk4 = ctx.edge(i16, &.{ 0, 255 });
            p.unk8 = ctx.edge(i16, &.{ 320, 240, 0, -1 });
            p.unkA = ctx.edge(i16, &.{ 240, 0, 239 });
        } else {
            p.unk0 = ctx.int(i16);
            p.unk2 = ctx.int(i16);
            p.unk4 = ctx.int(i16);
            p.unk8 = ctx.pick(i16, &.{ 320, 0, -1 });
            p.unkA = ctx.pick(i16, &.{ 240, 0 });
        }
        if (p.unk4 == -768) p.unk4 = -767;
    }

    // The exact boundary: x = unk0 and y = unk2 (divisor 4096), so the
    // `x < 320` and `y < 240` compares see 319 and 239, and so do the
    // `unk8 < 320` and `unkA < 240` compares.
    if (ctx.chance(4)) {
        const p = &parts[0];
        p.unk0 = 319;
        p.unk2 = 239;
        p.unk4 = 256;
        p.unk8 = 319;
        p.unkA = 239;
    }

    v.g.D_800F1DD4().* = &parts[0];
    v.g.D_800F1DC0().* = ctx.edge(i16, &.{ -1, 0, 1, 2, 3, 4, 5, 6 });
    v.g.D_800F1BA4().* = if (ctx.chance(2)) 0 else ctx.edge(u16, &.{ 1, 0x8000, 0xFFFF });
    v.g.D_800F1DC7().* = ctx.edge(u8, &.{ 0, 1, 32, 95, 96, 97, 255 });
    v.g.vs_gametime_tickspeed().* = ctx.edge(i32, &.{ -1, 0, 1, 2, 3, 4, 5 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if (v.g.D_800F1DC0().* <= 0) return 0;
    const p = v.g.D_800F1DD4().*.?;
    if (p.unk0 == 319 and p.unk2 == 239 and p.unk4 == 256 and p.unk8 == 319 and p.unkA == 239) return 3;
    if (v.g.D_800F1BA4().* == 0) return 1;
    return 2;
}
