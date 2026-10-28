//! zig_diff spec: _previousHitFactor1 -> previous_hit_factor1.previousHitFactor1 (146C.c).
//! Inputs: the battle state block with its unk4C[0] entity's hp and mp (edge
//! values, so the sum is often negative), an action whose two hitParams get
//! random 5-bit statFactors, the index 0 or 1, the unused entity pointers null
//! or valid, and unk0 at its wrap edges (0 makes unk0 - 1 wrap as u32). The
//! division by 10 truncates toward zero on a signed product, so the sign of
//! hp + mp times statFactor is the class.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").previousHitFactor1));

pub const classes = [_][:0]const u8{ "negative-product", "zero-product", "positive-product" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    for (&action.hitParams) |*hp| psx.setBits(hp, "statFactor", ctx.int(u5));

    const block = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = block;
    block.unk0 = ctx.pick(u32, &.{ 0, 1, 0x7FFF_FFFF, 0xFFFF_FFFF });

    const entity: *v._hitEntity_t = &block.unk8.unk4C[0];
    const edges16 = [_]i16{ 0, 1, -1, 100, -100, 32767, -32768 };
    entity.unk0.hp = ctx.pick(i16, &edges16);
    entity.unk0.mp = ctx.pick(i16, &edges16);

    const e1: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    const e2: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    const idx = ctx.edge(c_int, &.{ 0, 1 });

    return .{ action, e1, e2, idx, ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const block = v.g.D_800F19CC().*.?;
    const e = block.unk8.unk4C[0].unk0;
    const sum: i32 = @as(i32, e.hp) + @as(i32, e.mp);
    const sf: i32 = psx.getBits(&args[0].?.hitParams[@intCast(args[3])], "statFactor");
    const product = sum * sf;
    if (product < 0) return 0;
    if (product == 0) return 1;
    return 2;
}
