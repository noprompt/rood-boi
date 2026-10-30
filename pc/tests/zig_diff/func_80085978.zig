//! zig_diff spec: func_80085978 -> func_80085978.func_80085978 (146C.c).
//! Inputs: an arbitrary arg0 (zero, -1, the int extremes and random), and
//! arg1 in 0..15, the vs_battle_actors slots. Each used slot holds an actor
//! in the arena, since the C dereferences it without a guard. The actor's
//! stats field is null, a guest address below 2^31, or a guest address with
//! the sign bit set (random, 4-aligned, never dereferenced by the C), so the
//! raw 4-byte value reaches the call both ways. The C only passes that value
//! to _getActionCost, whose stub is a recording stub with a ctx.value result
//! the C discards: it reads nothing back.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80085978));

pub const classes = [_][:0]const u8{ "stats-null", "stats-low", "stats-high" };

pub const stubs = struct {
    /// The cost is discarded by the C and nothing else is read back, so the
    /// stub only returns a value (the same in both runs).
    pub fn _getActionCost(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) c_int {
        _ = a;
        _ = b;
        _ = c;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7fff_ffff, std.math.minInt(c_int) });
    const index = ctx.range(c_int, 0, 15);

    switch (ctx.value(u2) % 3) {
        0 => psx.put(&actor.stats, null),
        1 => psx.put(&actor.stats, stats),
        else => {
            // A guest address, 4-aligned and nonzero, never dereferenced
            // by the C: the low bit pattern decides the low/high class.
            const raw: u32 = @max(4, ctx.int(u32) & ~@as(u32, 3));
            const p: *v.vs_battle_actor2 = @ptrFromInt(raw);
            psx.put(&actor.stats, p);
        },
    }

    const table = v.g.vs_battle_actors();
    table[@intCast(index)] = actor;
    return .{ arg0, index };
}

pub fn classify(args: Args) usize {
    const actor = v.g.vs_battle_actors()[@intCast(args[1])].?;
    const raw = psx.rawOf(actor.stats);
    if (raw == 0) return 0;
    return if (raw & 0x8000_0000 == 0) 1 else 2;
}
