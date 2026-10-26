//! zig_diff spec: _calculateArmorClassAffinity -> calculate_armor_class_affinity.calculateArmorClassAffinity (146C.c).
//! The actor is a random vs_battle_actor2 in the arena, with a padding object on
//! each side so that limb indices -1 and 6 read and write inside harness memory.
//! Limb indices 0-5 are the normal case; -1 and 6 are the out-of-range case the C
//! allows. The C calls nothing, so there are no stubs. Every byte of the actor
//! is random, which covers signed classes and affinities (i8 read as u_short),
//! and unk88 values whose sum with the affinity wraps the i16 store.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").calculateArmorClassAffinity));

pub const classes = [_][:0]const u8{ "limb-in-range", "limb-out-of-range" };

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx.alloc(v.vs_battle_actor2); // room below: limbs[-1] is read
    const actor = ctx.alloc(v.vs_battle_actor2);
    _ = ctx.alloc(v.vs_battle_actor2); // room above: limbs[6] is read
    const limb = ctx.edge(c_int, &.{ 0, 1, 2, 3, 4, 5, -1, 6 });
    return .{ actor, limb };
}

pub fn classify(args: Args) usize {
    return if (args[1] >= 0 and args[1] < 6) 0 else 1;
}
