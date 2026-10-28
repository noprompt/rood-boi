//! zig_diff spec: func_80086EF4 -> func_80086EF4.func_80086EF4 (146C.c).
//! Inputs: an actor in the arena, preceded by padding so negative indices stay in
//! the arena. The shield's base id and each of the six limb armor ids are zero or
//! nonzero, with and without the sign bit (0x8000). The two indices are small
//! edges from -2 to 15 (past both affinity rows of 8, still inside the actor), and
//! arg2 equals arg1 about a quarter of the time. arg3 takes the wrap edges (0,
//! +-1, 32767, -32768, 65536, INT_MIN, INT_MAX), so the i16 affinity and unk
//! stores wrap. The function makes no calls, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80086EF4));

pub const classes = [_][:0]const u8{ "shield-empty", "same-index", "distinct-indices" };

const ids = [_]u16{ 1, 0x7FFF, 0x8000, 0xFFFF };
const index_edges = [_]c_int{ 0, 1, 2, 3, 5, 6, 7, 8, 9, -1, -2, 15 };

pub fn prepare(ctx: *zd.Ctx) Args {
    // Room below the actor for the negative index edges.
    _ = ctx.allocBytes(256, 16);
    const actor = ctx.alloc(v.vs_battle_actor2);

    actor.shield.base.id = if (ctx.chance(4)) 0 else ctx.pick(u16, &ids);
    for (0..6) |i| {
        actor.limbs[i].armor.armor.id = if (ctx.chance(3)) 0 else ctx.pick(u16, &ids);
    }

    const a1 = ctx.edge(c_int, &index_edges);
    const a2 = if (ctx.chance(4)) a1 else ctx.edge(c_int, &index_edges);
    const a3 = ctx.pick(c_int, &.{ 0, 1, -1, 32767, -32768, 65536, std.math.minInt(c_int), std.math.maxInt(c_int) });

    return .{ actor, a1, a2, a3 };
}

pub fn classify(args: Args) usize {
    const actor = args[0].?;
    if (actor.shield.base.id == 0) return 0;
    if (args[1] == args[2]) return 1;
    return 2;
}
