//! zig_diff spec: func_80085008 -> func_80085008.func_80085008 (146C.c).
//! Inputs: a random _hitEntity_t (hpEffect 0-3, any targetActor, but 0 in a
//! third of the runs and otherwise 0-15 so the table read stays in bounds),
//! an arena stats block whose limb indices unk34/unk35 are often 0 and
//! otherwise small or any byte (reads past limbs[6] stay in the arena), and
//! a random statuses word (bit 4 set or clear). Limb hp values come from edge
//! sets (0, 1, 2, -1, 0x7fff, -0x8000) so the sums and differences hit the
//! `== 1` and `== 2` edges of the comparisons. The status-effect masks and
//! D_800E8200 are set by prepare (the entries are in range). The two status
//! calls are recording stubs that write the argument and the target's
//! statuses, so the C's re-read of statuses in the loop is exercised.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80085008));

pub const classes = [_][:0]const u8{
    "no-limb-index",
    "flagged-limb",
    "unflagged-limb",
    "target0-flagged",
    "target0-unflagged",
};

/// The stats block of the current run: the stubs write it, classify reads it.
var g_stats: ?*v.vs_battle_actor2 = null;

fn limbIndex(ctx: *zd.Ctx) u8 {
    if (ctx.chance(4)) return 0;
    return ctx.pick(u8, &.{ 1, 2, 3, 5, 6, 7, 255 });
}

fn hpEdge(ctx: *zd.Ctx) i16 {
    return ctx.pick(i16, &.{ 0, 1, 2, 3, -1, 0x7fff, -0x8000 });
}

fn touch(ctx: *zd.Ctx, arg: anytype) void {
    const p: ?*v._hitEntity_t = @ptrCast(@alignCast(arg));
    const h = p orelse return;
    if (ctx.value(u1) == 1) h.inflictStatuses = ctx.value(i32);
    if (ctx.value(u1) == 1) h.removeStatuses = ctx.value(i32);
    if (ctx.value(u1) == 1) {
        if (g_stats) |s| s.statuses = ctx.value(i32);
    }
}

pub const stubs = struct {
    pub fn _setApplicableStatuses(ctx: *zd.Ctx, status: anytype, arg: anytype) c_int {
        _ = status;
        touch(ctx, arg);
        return ctx.value(c_int);
    }
    pub fn _setInflictedStatuses(ctx: *zd.Ctx, status: anytype, arg: anytype) c_int {
        _ = status;
        touch(ctx, arg);
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const stats = ctx.alloc(v.vs_battle_actor2);
    const actor = ctx.alloc(v.vs_battle_actor);
    const arg = ctx.alloc(v._hitEntity_t);
    g_stats = stats;

    psx.put(&actor.stats, stats);

    const target: u8 = if (ctx.chance(3)) 0 else ctx.range(u8, 0, 15);
    arg.unk0.targetActor = target;
    v.g.vs_battle_actors()[target] = actor;
    psx.setBits(arg, "hpEffect", ctx.int(u2));

    psx.setBits(stats, "unk34", limbIndex(ctx));
    psx.setBits(stats, "unk35", limbIndex(ctx));
    stats.statuses = ctx.int(i32);

    for (0..6) |i| {
        stats.limbs[i].hp = hpEdge(ctx);
        arg.limbs[i].hp = @as(u32, @as(u16, @bitCast(hpEdge(ctx))));
    }

    const masks = v.g.vs_main_statusEffectParams();
    for (0..5) |k| masks[k][0] = ctx.pick(i32, &.{ 0, 0x10, -1 });

    const table = v.g.D_800E8200();
    for (0..4) |i| table[i] = ctx.edge(u8, &.{ 0, 1, 2, 3, 4 });

    return .{arg};
}

pub fn classify(args: Args) usize {
    const arg = args[0].?;
    const stats = g_stats.?;
    if (psx.getBits(stats, "unk34") == 0 and psx.getBits(stats, "unk35") == 0) return 0;
    const flagged = (stats.statuses & 0x10) != 0;
    if (arg.unk0.targetActor == 0) return if (flagged) 3 else 4;
    return if (flagged) 1 else 2;
}
