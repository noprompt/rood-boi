//! zig_diff spec: _factorMagicDamageReceivedOfType -> factor_magic_damage_received_of_type.factorMagicDamageReceivedOfType (146C.c).
//! Inputs: the battle's current action index (0-255, the table's size), whether that action is a spell, the
//! hit entity's 2-bit hpEffect (1 and 3 are the two values that pass; 0 and 2 fail), random hp and mp (i16 edges,
//! so the sum, the /10 of a negative product and the short return all wrap), and statFactor (0-31) in the slot
//! hitParams[arg3] for arg3 in -8..8. The action sits inside a larger arena block so those slots stay owned.
//! arg1, arg2 and arg4 are unused by the C: null or a valid entity, and any int.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").factorMagicDamageReceivedOfType));

pub const classes = [_][:0]const u8{ "not-spell", "spell-hpEffect-1", "spell-hpEffect-3", "spell-other-hpEffect" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = d;

    // Action index: mostly the table's ends and middle, otherwise any entry of the 256.
    const idx: u16 = if (ctx.chance(2)) ctx.edge(u16, &.{ 0, 1, 127, 255 }) else ctx.range(u16, 0, 255);
    d.unk8.actionIndex = idx;

    const actions = v.g.actions();
    const spell = ctx.chance(3);
    const t: u3 = if (spell) 1 else ctx.edge(u3, &.{ 0, 2, 3, 4, 5, 6, 7 });
    psx.setBits(&actions[idx], "type", t);

    const he: u2 = ctx.edge(u2, &.{ 0, 1, 1, 2, 3, 3 });
    psx.setBits(&d.unk8.unk4, "hpEffect", he);
    d.unk8.unk4.unk0.hp = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 100 });
    d.unk8.unk4.unk0.mp = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 99 });

    // The action lives 128 bytes into a block, so hitParams[-8..8] are all inside owned memory.
    const block = ctx.allocBytes(256, 16);
    const action: *v.vs_action_t = @ptrCast(@alignCast(block + 128));
    const arg3 = ctx.range(c_int, -8, 8);
    const slot = psx.at(&action.hitParams, arg3);
    psx.setBits(slot, "statFactor", ctx.pick(u5, &.{ 0, 1, 10, 31 }));

    const e1: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    const e2: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    const arg4 = ctx.pick(c_int, &.{ 0, -1, 1, 0x7fffffff });
    return .{ action, e1, e2, arg3, arg4 };
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F19CC().*.?;
    const actions = v.g.actions();
    if (psx.getBits(&actions[d.unk8.actionIndex], "type") != 1) return 0;
    const he = psx.getBits(&d.unk8.unk4, "hpEffect");
    if (he == 1) return 1;
    if (he == 3) return 2;
    return 3;
}
