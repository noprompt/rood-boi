//! zig_diff spec: _breakArtsUnlocked -> break_arts_unlocked.breakArtsUnlocked (5BF94.c).
//! Inputs: an arena actor as vs_battle_characterState with its weapon
//! category 0 to 18 (0 makes the index use cat - 1 = -1, and 18 is the
//! last category whose four entries stay inside vs_main_actions). The
//! unlocked bits of the four entries are set so the first unlocked one is
//! at each position 0 to 3, or none is unlocked; the entries after the
//! first unlocked one get random bits, so the loop's later reads matter.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").breakArtsUnlocked));

pub const classes = [_][:0]const u8{ "hit-0", "hit-1", "hit-2", "hit-3", "none" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const cat = ctx.range(u8, 0, 18);
    actor.equippedWeaponCategory = cat;
    v.g.vs_battle_characterState().* = actor;

    // hit = the first unlocked position; 4 means none is unlocked.
    const hit = ctx.range(u8, 0, 4);
    const actions = v.g.actions();
    const base: i32 = 0xB8 + (@as(i32, cat) - 1) * 4;
    for (0..4) |j| {
        const idx: usize = @intCast(base + @as(i32, @intCast(j)));
        const bit: u1 = if (j < hit) 0 else if (j == hit) 1 else ctx.int(u1);
        psx.setBits(&actions[idx], "unlocked", bit);
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const cat: i32 = v.g.vs_battle_characterState().*.?.equippedWeaponCategory;
    const base: i32 = 0xB8 + (cat - 1) * 4;
    const actions = v.g.actions();
    for (0..4) |i| {
        const idx: usize = @intCast(base + @as(i32, @intCast(i)));
        if (psx.getBits(&actions[idx], "unlocked") != 0) return i;
    }
    return 4;
}
