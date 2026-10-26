//! zig_diff spec: func_8007CEC0 -> func_8007CEC0.func_8007CEC0 (146C.c).
//! Inputs: the 16-entry vs_battle_actors table (per call, all empty, all set,
//! or a random mix of null and arena actors). The callee func_8007CEA0 is a
//! recording stub that can clear a later entry or copy one entry over another,
//! so the C's per-iteration re-reads of the table are checked. Entries the
//! C never dereferences: only their nullness matters.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CEC0));

pub const classes = [_][:0]const u8{ "none-set", "all-set", "mixed" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const tbl = v.g.vs_battle_actors();
    const mode = ctx.range(u8, 0, 3);
    for (0..16) |i| {
        tbl[i] = switch (mode) {
            0 => null,
            1 => ctx.alloc(v.vs_battle_actor),
            else => if (ctx.chance(2)) null else ctx.alloc(v.vs_battle_actor),
        };
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const tbl = v.g.vs_battle_actors();
    var nulls: usize = 0;
    for (0..16) |i| {
        if (tbl[i] == null) nulls += 1;
    }
    if (nulls == 16) return 0;
    if (nulls == 0) return 1;
    return 2;
}

pub const stubs = struct {
    /// The real callee may empty a later table slot or copy one over another
    /// slot; the C must re-read the table on each iteration.
    pub fn func_8007CEA0(ctx: *zd.Ctx, i: anytype) void {
        const tbl = v.g.vs_battle_actors();
        const base: usize = @intCast(i);
        if (ctx.value(u1) == 1) tbl[(base + 1) & 15] = null;
        if (ctx.value(u1) == 1) tbl[(base + 3) & 15] = tbl[(base + 5) & 15];
    }
};
