//! zig_diff spec: _factorMagicDamageReceived -> factor_magic_damage_received.factorMagicDamageReceived (146C.c).
//! Inputs: an action in the arena with a random statFactor in each hitParams slot, a D_800F19CC_t in the
//! arena (its global pointer set by prepare) whose actionIndex is 0-255 (within vs_main_actions) and whose
//! action type is spell about three times in four, a random hpEffect (0-3), and hp and mp drawn from edge
//! values and any i16, so the sum wraps and goes negative. arg3 is an edge index into hitParams (including
//! -1 and -2, which stay inside the arena). arg1, arg2 and arg4 are unused by the C.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").factorMagicDamageReceived));

pub const classes = [_][:0]const u8{
    "not-spell",
    "spell-hpEffect-other",
    "spell-negative-sum",
    "spell-positive-sum",
    "spell-result-overflows-short",
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    const d = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = d;

    const idx: u8 = ctx.range(u8, 0, 255);
    d.unk8.actionIndex = idx;
    const t: u3 = if (ctx.chance(3)) ctx.range(u3, 0, 7) else 1;
    psx.setBits(&v.g.actions()[idx], "type", t);

    psx.setBits(&d.unk8.unk4, "hpEffect", ctx.int(u2));
    d.unk8.unk4.unk0.hp = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });
    d.unk8.unk4.unk0.mp = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });

    psx.setBits(&action.hitParams[0], "statFactor", ctx.int(u5));
    psx.setBits(&action.hitParams[1], "statFactor", ctx.int(u5));

    const arg3 = ctx.edge(c_int, &.{ 0, 1, -1, -2, 2 });
    return .{ action, null, null, arg3, ctx.int(c_int) };
}

pub fn classify(args: Args) usize {
    const action = args[0].?;
    const d = v.g.D_800F19CC().*.?;
    if (psx.getBits(&v.g.actions()[d.unk8.actionIndex], "type") != 1) return 0;
    const e = psx.getBits(&d.unk8.unk4, "hpEffect");
    if (e != 1 and e != 3) return 1;
    const sum: i32 = @as(i32, d.unk8.unk4.unk0.hp) + d.unk8.unk4.unk0.mp;
    const sf: i32 = psx.getBits(psx.at(&action.hitParams, args[3]), "statFactor");
    const r = @divTrunc(sum * sf, 10);
    if (r > 32767 or r < -32768) return 4;
    return if (sum < 0) 2 else 3;
}
