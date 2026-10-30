//! zig_diff spec: vs_battle_chainAbilitiesUnlocked -> chain_abilities_unlocked.chainAbilitiesUnlocked (5BF94.c).
//! Inputs: defense either 0 (the chain offsets) or another value, both
//! offset tables random (every u8 index, 0 and 255 included, so the lookups
//! reach any of the 256 actions), and every action's unlocked bit set with a
//! random density (from almost none to about one in forty), so the loop
//! returns 1 at each position 0-13 in turn and also falls through to 0. The
//! four classes split defense == 0 from the rest, and a hit from a miss.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").chainAbilitiesUnlocked));

pub const classes = [_][:0]const u8{
    "zero-hit",
    "zero-miss",
    "nonzero-hit",
    "nonzero-miss",
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const offs_c = v.g.vs_battle_chainAbilityOffsets();
    const offs_d = v.g.vs_battle_defenseAbilityOffsets();
    const acts = v.g.actions();

    for (0..16) |i| {
        offs_c[i] = ctx.pick(u8, &.{ 0, 1, 13, 127, 128, 255 });
        offs_d[i] = ctx.pick(u8, &.{ 0, 1, 13, 127, 128, 255 });
    }

    // Density of unlocked actions: sometimes almost none, so the loop runs out.
    const dens: u32 = ctx.edge(u32, &.{ 40, 150, 1000 });
    for (0..256) |j| {
        psx.setBits(&acts[j], "unlocked", @intFromBool(ctx.chance(dens)));
    }

    const defense: c_int = if (ctx.chance(3))
        0
    else
        ctx.pick(c_int, &.{ 1, -1, 13, 14, 255, 256 });
    return .{defense};
}

fn hit(defense: c_int) bool {
    const offs_c = v.g.vs_battle_chainAbilityOffsets();
    const offs_d = v.g.vs_battle_defenseAbilityOffsets();
    const acts = v.g.actions();
    for (0..14) |i| {
        const idx = if (defense == 0) offs_c[i] else offs_d[i];
        if (psx.getBits(&acts[idx], "unlocked") != 0) return true;
    }
    return false;
}

pub fn classify(args: Args) usize {
    const defense = args[0];
    const h = hit(defense);
    const base: usize = if (defense == 0) 0 else 2;
    return base + (if (h) @as(usize, 0) else 1);
}
