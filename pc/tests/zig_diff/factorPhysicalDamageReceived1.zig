//! zig_diff spec: _factorPhysicalDamageReceived1 -> factor_physical_damage_received1.factorPhysicalDamageReceived1 (146C.c).
//! Inputs: the current-action record D_800F19CC (a fresh arena object) with an
//! action index 0..255 into vs_main_actions, whose type is spell (1) or not;
//! the hit effect 0-3 (both arms of the `||` and the fall-through); hp and mp
//! across the i16 range (negative sums, the signed `/ 10`); the action's
//! hitParams statFactor (5 bits, random) read at arg3 0..3 (2 and 3 read
//! inside the action's name array, as the C does). The action is always a
//! valid arena object: the C only dereferences it on some paths, but a
//! mutated test can route it there, so a null action would fault the mutant
//! rather than show a difference. The C calls nothing, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").factorPhysicalDamageReceived1));

pub const classes = [_][:0]const u8{ "spell", "effect-0-or-2", "effect-1", "effect-3" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const hit = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = hit;

    const acts = v.g.actions();
    const idx = ctx.edge(u16, &.{ 0, 1, 2, 7, 100, 255 });
    hit.unk8.actionIndex = idx;
    const spell = ctx.chance(4);
    psx.setBits(&acts[idx], "type", if (spell) 1 else ctx.edge(u3, &.{ 0, 2, 3, 4, 5, 6, 7 }));

    const eff = ctx.edge(u2, &.{ 0, 1, 2, 3 });
    psx.setBits(&hit.unk8.unk4, "hpEffect", eff);
    hit.unk8.unk4.unk0.hp = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
    hit.unk8.unk4.unk0.mp = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });

    const action = ctx.alloc(v.vs_action_t);
    for (&action.hitParams) |*slot| psx.setBits(slot, "statFactor", ctx.int(u5));
    const arg3: c_int = ctx.edge(c_int, &.{ 0, 1, 2, 3 });

    const h1: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    const h2: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);

    return .{ action, h1, h2, arg3, ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    _ = args;
    const hit = v.g.D_800F19CC().*.?;
    const acts = v.g.actions();
    if (psx.getBits(&acts[hit.unk8.actionIndex], "type") == 1) return 0;
    const e = psx.getBits(&hit.unk8.unk4, "hpEffect");
    if (e == 1) return 2;
    if (e == 3) return 3;
    return 1;
}
