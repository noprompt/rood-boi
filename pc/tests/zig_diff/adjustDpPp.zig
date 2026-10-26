//! zig_diff spec: _adjustDpPp -> adjust_dp_pp.adjustDpPp (146C.c).
//! Inputs: an action (spell or not, with type 0-7), a source and a target
//! actor2 in the arena, and 16 actor objects behind vs_battle_actors (the
//! target's unk957 picks one of them, so the weaponDrawn bit 0 test sees both
//! values, with and without the sign bit). The armor table holds zeros,
//! positive and negative entries; the limb DP values equal their table entry
//! often, so the `>=` tests see equal sides. The amount is small (equal to
//! the DP fields often), a negative or wrapping edge, or any c_int. Negative
//! amounts reach the signed compares of the weapon and shield DP. The C
//! calls nothing, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").adjustDpPp));

pub const classes = [_][:0]const u8{ "spell", "undrawn", "drawn-shield-equal", "drawn-shield-other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    const source = ctx.alloc(v.vs_battle_actor2);
    const target = ctx.alloc(v.vs_battle_actor2);

    const spell = ctx.chance(3);
    psx.setBits(action, "type", if (spell) 1 else ctx.edge(u3, &.{ 0, 2, 3, 4, 5, 6, 7 }));

    const amount: c_int = if (ctx.chance(2))
        ctx.range(c_int, 0, 300)
    else
        ctx.pick(c_int, &.{ 0, 1, -1, 65535, 65536, -65536, 0x7FFF_FFFF, -0x8000_0000 });
    const in16 = amount >= 0 and amount <= 65535;

    source.weapon.currentDp = if (in16 and ctx.chance(3))
        @as(u16, @intCast(amount))
    else
        ctx.pick(u16, &.{ 0, 1, 65535 });

    target.shield.currentDp = if (in16 and ctx.chance(3))
        @as(u16, @intCast(amount))
    else
        ctx.pick(u16, &.{ 0, 1, 65535 });

    target.unk957 = ctx.range(u8, 0, 15);

    const table = v.g._armorDpAdjustmentAmounts();
    for (0..8) |i| table[i] = ctx.pick(i16, &.{ 0, 0, 1, -1, 5, 32767, -32768 });

    for (0..6) |i| {
        const a = table[i];
        target.limbs[i].armor.currentDp = if (a >= 0 and ctx.chance(2))
            @as(u16, @intCast(a))
        else
            ctx.pick(u16, &.{ 0, 1, 65535 });
    }

    const tbl = v.g.vs_battle_actors();
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        actor.weaponDrawn = ctx.pick(i32, &.{ 0, 1, 2, 3, -1, -2, 0x7FFF_FFFE, -0x8000_0000 });
        tbl[i] = actor;
    }

    return .{ action, source, target, amount };
}

pub fn classify(args: Args) usize {
    const action = args[0].?;
    const target = args[2].?;
    if (psx.getBits(action, "type") == 1) return 0;
    const tbl = v.g.vs_battle_actors();
    const drawn = (tbl[target.unk957].?.weaponDrawn & 1) != 0;
    if (!drawn) return 1;
    if (@as(c_int, target.shield.currentDp) == args[3]) return 2;
    return 3;
}
