//! zig_diff spec: func_80086EA4 -> func_80086EA4.func_80086EA4 (146C.c).
//! Inputs: an actor2 in the arena whose blade id is zero or not (nonzero ids
//! with and without the sign bit, and ids whose low byte is zero, which the
//! C's `!= 0` test takes as set), two indices from -8..40 (inside the actor's
//! weapon, past the affinity and unk168 arrays at both ends, and equal about a
//! third of the time so the two writes alias), and an addend from the i16
//! wrap edges and the full non-overflowing int range. The addend stays within
//! +-0x3FFFFFFF so the C's `int` sums cannot overflow.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80086EA4));

pub const classes = [_][:0]const u8{ "no-blade", "blade-low-byte-zero", "same-index", "distinct-index" };

fn index(ctx: *zd.Ctx) c_int {
    if (ctx.chance(2)) return ctx.edge(c_int, &.{ 0, 1, 7, 8, 15, -1, -8 });
    return ctx.range(c_int, -8, 40);
}

fn addend(ctx: *zd.Ctx) c_int {
    if (ctx.chance(2)) return ctx.edge(c_int, &.{ 0, 1, -1, 0x7FFF, -0x8000, 0x8000, 0x10000, -0x10000, 0x3FFF_FFFF, -0x3FFF_FFFF });
    return ctx.range(c_int, -0x3FFF_FFFF, 0x3FFF_FFFF);
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor2);
    actor.weapon.blade.id = if (ctx.chance(4)) 0 else ctx.pick(u16, &.{ 0x100, 0x200, 0x8000, 0xFFFF, 1 });
    const arg1 = index(ctx);
    const arg2 = if (ctx.chance(3)) arg1 else index(ctx);
    const arg3 = addend(ctx);
    return .{ actor, arg1, arg2, arg3 };
}

pub fn classify(args: Args) usize {
    const actor = args[0].?;
    if (actor.weapon.blade.id == 0) return 0;
    if ((actor.weapon.blade.id & 0xFF) == 0) return 1;
    if (args[1] == args[2]) return 2;
    return 3;
}
