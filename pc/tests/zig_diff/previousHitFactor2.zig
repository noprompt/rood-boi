//! zig_diff spec: _previousHitFactor2 -> previous_hit_factor2.previousHitFactor2 (146C.c).
//! Inputs: the D_800F19CC object in the arena, reached through its global pointer,
//! with hp and mp from the i16 edges (mp is sometimes -hp, so the sum is zero), and
//! unk0 from the u32 edges (0 wraps the `- 1`). The action in the arena keeps its random
//! hitParams, and arg3 runs over both entries and the bytes past them. arg1 and arg2 are
//! unused by the C: null or an arena block. The C has no branches and no ordered
//! comparisons, so the classes only split the sign of the hp+mp sum.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").previousHitFactor2));

pub const classes = [_][:0]const u8{ "sum-negative", "sum-zero", "sum-positive" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    const data = ctx.alloc(v.D_800F19CC_t);
    const e = &data.unk8.unk4C[0].unk0;

    data.unk0 = ctx.pick(u32, &.{ 0, 1, 0xFFFF_FFFF, 0x8000_0000 });
    e.hp = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 999 });
    e.mp = if (ctx.chance(4)) 0 -% e.hp else ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 999 });
    v.g.D_800F19CC().* = data;

    const a1: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    const a2: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);

    return .{ action, a1, a2, ctx.edge(c_int, &.{ 0, 1, 2, 3, 5 }), ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    _ = args;
    const e = v.g.D_800F19CC().*.?.unk8.unk4C[0].unk0;
    const sum = @as(i32, e.hp) + @as(i32, e.mp);
    return if (sum < 0) 0 else if (sum == 0) 1 else 2;
}
