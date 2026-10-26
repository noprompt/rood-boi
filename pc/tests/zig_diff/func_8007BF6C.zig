//! zig_diff spec: func_8007BF6C -> func_8007BF6C.func_8007BF6C (146C.c).
//! Inputs: an index 0-15 into vs_battle_actors, the table's 16 entries each
//! null or a fresh arena actor (random per entry, so a port that reads the
//! wrong slot differs). The callees are default recording stubs: the int
//! result of func_800A0BE0 is `ctx.value`, and func_800A087C is void. Nothing
//! the C reads back after the call, so no stub writes state.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007BF6C));

pub const classes = [_][:0]const u8{ "slot-null", "slot-live" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        table[i] = if (ctx.chance(2)) null else ctx.alloc(v.vs_battle_actor);
    }
    const idx: c_int = ctx.range(i32, 0, 15);
    return .{idx};
}

pub fn classify(args: Args) usize {
    const table = v.g.vs_battle_actors();
    return if (table[@intCast(args[0])] == null) 0 else 1;
}
