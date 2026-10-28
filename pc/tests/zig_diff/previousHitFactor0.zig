//! zig_diff spec: _previousHitFactor0 -> previous_hit_factor0.previousHitFactor0 (146C.c).
//! The C has no branches and no calls: it is (hp + mp) * hitParams[arg3].statFactor / 10
//! plus (D_800F19CC->unk0 - 1), truncated to short. The inputs: a vs_action_t in the arena
//! with room on both sides (so the indices the C allows, -2..3, stay in memory the harness
//! owns), random statFactors (0..31), hp and mp at the i16 extremes (negative sums, so the
//! C's signed division matters), unk0 at 0, 1 and 0xFFFFFFFF (the subtraction wraps), and
//! arg1/arg2/arg4 null or random (unused by the C). classify separates the in-range
//! indices 0 and 1 from the out-of-range ones.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").previousHitFactor0));

pub const classes = [_][:0]const u8{ "index-in-range", "index-out-of-range" };

pub fn prepare(ctx: *zd.Ctx) Args {
    // Room before and after the action so hitParams[-2..3] stay inside the arena.
    const blk = ctx.allocBytes(256, 16);
    const act: *v.vs_action_t = @ptrCast(@alignCast(blk + 64));
    for (0..2) |k| psx.setBits(&act.hitParams[k], "statFactor", ctx.int(u5));

    const d = ctx.alloc(v.D_800F19CC_t);
    d.unk8.unk4C[0].unk0.hp = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });
    d.unk8.unk4C[0].unk0.mp = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });
    d.unk0 = ctx.pick(u32, &.{ 0, 1, 2, 0xFFFF_FFFF, 0x8000_0000 });
    v.g.D_800F19CC().* = d;

    const idx = ctx.edge(c_int, &.{ 0, 1, 0, 1, -1, 2, -2, 3 });
    const e1: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    const e2: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    return .{ act, e1, e2, idx, ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const i = args[3];
    return if (i == 0 or i == 1) 0 else 1;
}
