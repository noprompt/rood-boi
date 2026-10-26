//! zig_diff spec: func_8008FAC8 -> func_8008FAC8.func_8008FAC8 (146C.c).
//! Inputs: a particle array of up to 40 entries in the arena (skip flag
//! unkC zero or not, unkF any byte, unk2 set so the decrement lands on
//! exactly -1024 about a third of the time, and at the i16 edges), a count
//! from -3 to 40, a tick speed of -3..3, the paused flag, and the widescreen
//! flag at 0, 1 and -1. The scratchpad's view-matrix pointer is the arena's
//! prim list, the ordering table pointer is an arena block. RotTransPers
//! writes screen x and y around the edges of both tests (y in -8..247, x in
//! -60..451) and returns depths on both sides of 64 and 2048, exactly at
//! 64, 2047 and 2048 often enough for the equal-sides boundary flags, and in
//! between. func_8008FA14 rewrites unk2 (and sometimes unkC), which the C
//! re-reads. SetRotMatrix, SetTransMatrix, AddPrim and pc_insert_tpage only
//! record their calls.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008FAC8));

pub const classes = [_][:0]const u8{ "no-particles", "paused", "widescreen", "normal" };

pub const stubs = struct {
    pub fn RotTransPers(ctx: *zd.Ctx, v0: anytype, sxy: anytype, p: anytype, flag: anytype) c_int {
        _ = v0;
        _ = p;
        _ = flag;
        const xy: *align(1) [2]i16 = @ptrCast(sxy);
        xy[0] = @as(i16, @intCast(ctx.value(u9))) - 60;
        xy[1] = @as(i16, @intCast(ctx.value(u8))) - 8;
        const k = ctx.value(u8);
        if (k < 30) return 64;
        if (k < 60) return 2048;
        if (k < 72) return 2047;
        if (k < 100) return 65 + @as(c_int, @intCast(ctx.value(u11) % 1983));
        return ctx.value(c_int);
    }

    pub fn func_8008FA14(ctx: *zd.Ctx, particle: anytype) void {
        const p: *v.D_800F1DD4_t = @ptrCast(particle);
        p.unk2 = ctx.value(i16);
        if (ctx.value(u1) == 1) p.unkC = ctx.value(u8);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const n_max = 40;
    const prims: [*]v.POLY_G4 = @ptrCast(@alignCast(ctx.allocBytes(@sizeOf(v.POLY_G4) * n_max, 16)));
    const parts: [*]v.D_800F1DD4_t = @ptrCast(@alignCast(ctx.allocBytes(@sizeOf(v.D_800F1DD4_t) * n_max, 16)));
    const ot: *anyopaque = @ptrCast(ctx.allocBytes(8192 + 64, 16));

    const s: *v.vs_scratch_t = @ptrFromInt(0x1F800000);
    psx.put(&s.unk0, &prims[0]);
    psx.put(&s.unk4, ot);

    v.g.D_800F1DD4().* = &parts[0];
    const tick: i32 = ctx.range(i32, -3, 3);
    v.g.vs_gametime_tickspeed().* = tick;
    v.g.D_800F1BA4().* = if (ctx.chance(2)) 0 else ctx.pick(u16, &.{ 1, 0x8000 });
    v.g.pc_gte_widescreen().* = ctx.pick(i32, &.{ 0, 1, -1 });
    v.g.D_800F1DC0().* = ctx.range(i16, -3, n_max);

    for (0..n_max) |k| {
        const p = &parts[k];
        p.unkC = ctx.pick(u8, &.{ 0, 0x80, 1 });
        p.unkF = ctx.int(u8);
        if (ctx.chance(3)) {
            const base: i32 = -1024 + @as(i32, p.unkF) * tick + ctx.range(i32, -2, 2);
            p.unk2 = @intCast(base);
        } else {
            p.unk2 = ctx.pick(i16, &.{ -32768, 32767, 0 });
        }
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if (v.g.D_800F1DC0().* <= 0) return 0;
    if (v.g.D_800F1BA4().* != 0) return 1;
    if (v.g.pc_gte_widescreen().* != 0) return 2;
    return 3;
}
