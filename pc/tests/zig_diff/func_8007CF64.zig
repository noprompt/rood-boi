//! zig_diff spec: func_8007CF64 -> func_8007CF64.func_8007CF64 (146C.c).
//! Inputs: an actor id across the table's 16 slots (both ends included), and
//! the table itself: every slot an arena actor or null, the id's slot null
//! one time in four. The C has no branches; the value edges are the slot
//! contents (null and a live object) and the first and last indices.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CF64));

pub const classes = [_][:0]const u8{ "null-slot", "object-slot" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        table[i] = if (ctx.chance(4)) null else ctx.alloc(v.vs_battle_actor);
    }
    const id = ctx.range(c_int, 0, 15);
    return .{id};
}

pub fn classify(args: Args) usize {
    const table = v.g.vs_battle_actors();
    return if (table[@intCast(args[0])] == null) 0 else 1;
}
