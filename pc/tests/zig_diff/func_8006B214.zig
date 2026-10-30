//! zig_diff spec: func_8006B214 -> func_8006B214.func_8006B214 (146C.c).
//! Inputs: the global character actor in the arena (always valid), its stats
//! block (always valid, linked through the guest pointer field), and statuses
//! drawn from edge values around bit 20, both with and without the sign bit,
//! so the flag test sees the flag set and clear. unk957 is any byte. The
//! callees are recording stubs; func_80086754 may rewrite statuses.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006B214));

pub const classes = [_][:0]const u8{ "flag-clear", "flag-set" };

pub const stubs = struct {
    pub fn func_80086754(ctx: *zd.Ctx, flag: anytype, p: anytype) void {
        _ = flag;
        const s = asActor2(p);
        if (ctx.value(u1) == 1) s.statuses = ctx.value(i32);
    }
};

/// The stub's pointer argument as a view pointer, whether or not it is optional.
fn asActor2(p: anytype) *v.vs_battle_actor2 {
    const q = if (@typeInfo(@TypeOf(p)) == .optional) p.? else p;
    return @ptrCast(@alignCast(q));
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    psx.put(&actor.stats, stats);
    stats.statuses = ctx.pick(i32, &.{
        0,
        0x100000,
        -1,
        0x7FFFFFFF,
        -0x80000000,
        0x000FFFFF,
        0x7FEFFFFF,
        -0x7FF00000,
    });
    stats.unk957 = ctx.pick(u8, &.{ 0, 1, 255 });
    v.g.vs_battle_characterState().* = actor;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const actor = v.g.vs_battle_characterState().*.?;
    const stats = psx.get(actor.stats).?;
    return if ((stats.statuses & 0x100000) != 0) 1 else 0;
}
