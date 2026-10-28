//! zig_diff spec: _hitPrerequisiteCanApplyEffect -> hit_prerequisite_can_apply_effect.hitPrerequisiteCanApplyEffect (146C.c).
//! Inputs: a debuff index 0-4 (the statusEffectParams table's length) and an
//! actor index 0-15 (the vs_battle_actors table's length), so every entry the
//! C reads is a real actor that prepare sets. The actor's stats block sits in
//! the arena with random unk944 and statuses. The matching params words are
//! set so each mask test sees a zero AND, a nonzero AND with the sign bit, or
//! a nonzero AND without it. The C makes no calls, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyEffect));

pub const classes = [_][:0]const u8{ "first-mask-set", "only-second-set", "both-clear" };

/// Sets a params word and a state word so that their AND takes the shapes
/// the mask tests need: zero, sign bit set, and nonzero without the sign bit.
fn pairMask(ctx: *zd.Ctx, a: *i32, b: *i32) void {
    switch (ctx.range(u8, 0, 5)) {
        0 => {
            a.* = 0;
            b.* = ctx.int(i32);
        },
        1 => {
            a.* = ctx.int(i32);
            b.* = ~a.*;
        },
        2 => {
            a.* = @bitCast(@as(u32, 0x8000_0000));
            b.* = -1;
        },
        3 => {
            a.* = 1;
            b.* = ctx.pick(i32, &.{ 1, 3, -1, 0x7FFF_FFFF });
        },
        4 => {
            a.* = ctx.pick(i32, &.{ 0, -1, 0x7FFF_FFFF, -0x8000_0000 });
            b.* = ctx.pick(i32, &.{ 0, -1, 0x7FFF_FFFF, -0x8000_0000 });
        },
        else => {
            a.* = ctx.int(i32);
            b.* = ctx.int(i32);
        },
    }
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    psx.put(&actor.stats, stats);

    const idx = ctx.range(u8, 0, 15);
    const arg: [*c]u8 = ctx.alloc(u8);
    arg[0] = idx;
    v.g.vs_battle_actors()[idx] = actor;

    const debuff = ctx.range(c_int, 0, 4);
    const params = &v.g.vs_main_statusEffectParams()[@intCast(debuff)];
    pairMask(ctx, &params[0], &stats.unk944);
    pairMask(ctx, &params[3], &stats.statuses);

    return .{ debuff, arg };
}

pub fn classify(args: Args) usize {
    const params = &v.g.vs_main_statusEffectParams()[@intCast(args[0])];
    const actor = v.g.vs_battle_actors()[args[1][0]].?;
    const stats = psx.get(actor.stats).?;
    if ((params[0] & stats.unk944) != 0) return 0;
    if ((params[3] & stats.statuses) != 0) return 1;
    return 2;
}
