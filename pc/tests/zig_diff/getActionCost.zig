//! zig_diff spec: _getActionCost -> get_action_cost.getActionCost (146C.c).
//! Inputs: any action id 0-255 (the edges 21, 22, 39, 40 and 255 weighted in),
//! every action type 0-7 (the default prongs 0, 5 and 7 included), the base
//! attack path with every weapon action type 1-4, a random or small stat so
//! `statValue >= cost` is often an exact tie, a random or near-100 risk,
//! the D_800F19CC block with unk4 at the edges 0, 9, 10, 11, 100, 2^16,
//! 2^31-1, 2^31 and 2^32-1, and updateStat at 0, +-1, 256 and the sign-bit
//! patterns. The C calls no functions, so there are no stubs. The inner
//! base-attack switch has no default: a weapon action type outside 1-4 would
//! make the C read an uninitialised statValue, so prepare never builds one
//! (that arc is waived).
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getActionCost));

pub const classes = [_][:0]const u8{
    "default",
    "spell",
    "ability",
    "break-art",
    "pp",
    "base-spell",
    "base-ability",
    "base-break-art",
    "base-pp",
    "ability-bonus",
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor2);
    const dt = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = dt;
    dt.unk4 = ctx.pick(u32, &.{ 0, 9, 10, 11, 100, 0x10000, 0x7FFF_FFFF, 0x8000_0000, 0xFFFF_FFFF });

    const id: c_uint = if (ctx.chance(6))
        ctx.edge(c_uint, &.{ 0, 21, 22, 39, 40, 255 })
    else
        ctx.range(c_uint, 0, 255);
    const action = &v.g.actions()[id];
    const atype = ctx.range(u3, 0, 7);
    psx.setBits(action, "type", atype);
    action.cost = if (ctx.chance(4)) ctx.int(u8) else ctx.range(u8, 0, 8);

    actor.currentMP = if (ctx.chance(4)) ctx.int(i16) else ctx.range(i16, 0, 9);
    actor.currentHP = if (ctx.chance(4)) ctx.int(i16) else ctx.range(i16, 0, 9);
    actor.risk = if (ctx.chance(3)) ctx.range(u16, 92, 100) else ctx.int(u16);
    actor.weapon.currentPp = if (ctx.chance(4)) ctx.int(u16) else ctx.range(u16, 0, 9);
    actor.weapon.risk = if (ctx.chance(4)) ctx.int(u8) else ctx.range(u8, 0, 9);
    actor.weapon.actionType = if (atype == 6) ctx.range(u8, 1, 4) else ctx.int(u8);

    const updateStat = ctx.edge(c_int, &.{ 0, 1, -1, 256, -2147483648, 0x40000000 });
    return .{ id, actor, updateStat };
}

pub fn classify(args: Args) usize {
    const id: usize = args[0];
    const actor = args[1].?;
    const dt = v.g.D_800F19CC().*.?;
    const t = psx.getBits(&v.g.actions()[id], "type");
    const base = t == 6;
    const final: u8 = if (base) actor.weapon.actionType else t;
    if (final == 2 and dt.unk4 >= 10 and id >= 22 and id <= 39) return 9;
    if (base) {
        return switch (final) {
            1 => 5,
            2 => 6,
            3 => 7,
            4 => 8,
            else => 0,
        };
    }
    return switch (final) {
        1 => 1,
        2 => 2,
        3 => 3,
        4 => 4,
        else => 0,
    };
}
