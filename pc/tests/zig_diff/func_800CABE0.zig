//! zig_diff spec: func_800CABE0 -> func_800CABE0.func_800CABE0 (5BF94.c).
//! Inputs: the character state global points at an actor in the arena whose
//! stats block and weapon block are arena objects. Stats currentMP and
//! currentHP come from edges (0, 1, -1, the i16 extremes), statuses from
//! edges (none, Regen, StrDown, Ward, all bits), weaponDrawn is random, and
//! arg0 is one of 0, 1, 2, 3, -1. The func_800A0BE0 stub returns random 32-bit
//! flags, so both sides of the 0x80000 and 0x40100000 tests are taken, and
//! sometimes rewrites the stats and the weapon bit that the C reads after it.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CABE0));

pub const classes = [_][:0]const u8{ "mp-zero", "hp-zero", "undrawn", "arg2", "ward", "regen-strdown", "plain" };

pub const stubs = struct {
    pub fn func_800A0BE0(ctx: *zd.Ctx, arg: anytype) c_uint {
        _ = arg;
        const ch = v.g.vs_battle_characterState().*.?;
        const st = psx.get(ch.stats).?;
        const weapon = psx.get(ch.unk44).?;
        if (ctx.value(u8) < 96) st.currentMP = ctx.value(i16);
        if (ctx.value(u8) < 96) st.currentHP = ctx.value(i16);
        if (ctx.value(u8) < 96) st.statuses = ctx.value(i32);
        if (ctx.value(u8) < 96) psx.setBits(weapon, "weaponDrawn", ctx.value(u1));
        return ctx.value(c_uint);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    const weapon = ctx.alloc(v.D_800F4538_unk0);
    psx.put(&actor.stats, stats);
    psx.put(&actor.unk44, weapon);
    v.g.vs_battle_characterState().* = actor;
    stats.currentMP = ctx.pick(i16, &.{ 0, 1, -1, 0x7FFF, -0x8000 });
    stats.currentHP = ctx.pick(i16, &.{ 0, 1, -1, 0x7FFF, -0x8000 });
    stats.statuses = ctx.pick(i32, &.{ 0, 1, 8, 4096, 8192, 0x1000 | 0x2000, -1 });
    psx.setBits(weapon, "weaponDrawn", ctx.int(u1));
    return .{ctx.pick(c_int, &.{ 0, 1, 2, 3, -1 })};
}

pub fn classify(args: Args) usize {
    const ch = v.g.vs_battle_characterState().*.?;
    const st = psx.get(ch.stats).?;
    const weapon = psx.get(ch.unk44).?;
    if (st.currentMP == 0) return 0;
    if (st.currentHP == 0) return 1;
    if (psx.getBits(weapon, "weaponDrawn") == 0) return 2;
    if (args[0] == 2) return 3;
    if ((st.statuses & 0x2000) != 0) return 4;
    if ((st.statuses & 0x1001) != 0) return 5;
    return 6;
}
