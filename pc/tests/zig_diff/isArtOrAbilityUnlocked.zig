//! zig_diff spec: _isArtOrAbilityUnlocked -> is_art_or_ability_unlocked.isArtOrAbilityUnlocked (146C.c).
//! Inputs: the character's equipped weapon category (edges 0, 9, 10, 19, 20, 99,
//! 128, 255, so the % 10 is checked), its learned-art count (0-5 and 255, so
//! the `< 4` test sees equal sides), the weapon kill count against the art
//! requirement (equal, and the 0 / 65534 / 65535 extremes), and the battle
//! ability count (22 for the equal side, plus 0, 1, 21, 23, 65535) against
//! the total kills and the ability requirement (equal, and the extremes).
//! The requirement tables are rewritten every run. There are no callees.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").isArtOrAbilityUnlocked));

pub const classes = [_][:0]const u8{ "art-unlocked", "ability-unlocked", "ability-short", "abilities-maxed" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    actor.equippedWeaponCategory = ctx.pick(u8, &.{ 0, 9, 10, 19, 20, 99, 128, 255 });
    v.g.vs_battle_characterState().* = actor;
    const cat: usize = actor.equippedWeaponCategory % 10;

    // Every table entry the C can read: rows 0-9 of 4 entries, and 22 abilities.
    const reqs = v.g.vs_main_artsPointsRequirements();
    for (0..10) |row| {
        for (0..4) |col| {
            reqs[row][col] = ctx.pick(u16, &.{ 0, 1, 65535 });
        }
    }
    const abReqs = v.g.vs_main_battleAbilitiesPointsRequirements();
    for (0..22) |i| {
        abReqs[i] = ctx.pick(u16, &.{ 0, 1, 65535 });
    }

    const st = v.g.vs_main_artsStatus();
    st.artsLearned[cat] = ctx.pick(u8, &.{ 0, 1, 2, 3, 4, 5, 255 });
    const learned: usize = st.artsLearned[cat];
    if (learned < 4) {
        st.kills.weaponCategories[cat] = if (ctx.chance(3))
            reqs[cat][learned]
        else
            ctx.edge(u16, &.{ 0, 1, 65534, 65535 });
    }

    st.kills.battleAbilitiesUnlocked = if (ctx.chance(4)) 22 else ctx.edge(u16, &.{ 0, 1, 21, 23, 65535 });
    const ab: usize = st.kills.battleAbilitiesUnlocked;
    if (ab < 22) {
        st.kills.total = if (ctx.chance(3))
            abReqs[ab]
        else
            ctx.edge(u16, &.{ 0, 1, 65534, 65535 });
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const actor = v.g.vs_battle_characterState().*.?;
    const cat: usize = actor.equippedWeaponCategory % 10;
    const st = v.g.vs_main_artsStatus();
    const learned: usize = st.artsLearned[cat];
    if (learned < 4 and st.kills.weaponCategories[cat] >= v.g.vs_main_artsPointsRequirements()[cat][learned]) return 0;
    if (st.kills.battleAbilitiesUnlocked >= 22) return 3;
    if (st.kills.total >= v.g.vs_main_battleAbilitiesPointsRequirements()[st.kills.battleAbilitiesUnlocked]) return 1;
    return 2;
}
