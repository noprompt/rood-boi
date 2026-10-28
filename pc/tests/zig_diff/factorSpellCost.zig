//! zig_diff spec: _factorSpellCost -> factor_spell_cost.factorSpellCost (146C.c).
//! Inputs: a D_800F19CC object in the arena whose actionIndex is 0-255, with
//! vs_main_actions[actionIndex] a spell (type 1) one time in three and any
//! other type otherwise; the cost is a few edge values and any byte. The
//! action argument always points at an arena object whose hitParams
//! statFactors (5-bit) are random, and arg3 is an edge in -2..5 so the index
//! hits both slots and the reads just outside hitParams. The action is never
//! null: the C reads it only on the spell path, but a mistake that reads it
//! on the other path must show as a mismatch, not a crash. arg1, arg2 and
//! arg4 are unused by the C.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").factorSpellCost));

pub const classes = [_][:0]const u8{ "not-spell", "spell-arg3-zero", "spell-arg3-other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx.allocBytes(64, 16);
    const action = ctx.alloc(v.vs_action_t);
    _ = ctx.allocBytes(128, 16);
    const dat = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = dat;
    dat.unk8.actionIndex = ctx.range(u16, 0, 255);
    const act = &v.g.actions()[dat.unk8.actionIndex];
    const spell = ctx.chance(3);
    psx.setBits(act, "type", if (spell) @as(u3, 1) else ctx.edge(u3, &.{ 0, 2, 3, 4, 5, 6, 7 }));
    act.cost = ctx.pick(u8, &.{ 0, 1, 9, 10, 11, 255 });
    for (0..2) |i| psx.setBits(&action.hitParams[i], "statFactor", ctx.int(u5));
    const arg1: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    const arg2: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    const arg3 = ctx.edge(c_int, &.{ 0, 1, -1, 2, -2, 3, 5 });
    const arg4 = ctx.int(c_int);
    return .{ action, arg1, arg2, arg3, arg4 };
}

pub fn classify(args: Args) usize {
    const cur = v.g.D_800F19CC().*.?;
    const act = &v.g.actions()[cur.unk8.actionIndex];
    if (psx.getBits(act, "type") != 1) return 0;
    return if (args[3] == 0) 1 else 2;
}
