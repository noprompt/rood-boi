//! Fills a shield's display block from its base and gem stats (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const c = @import("c_146C");
const v = @import("views_146C");

/// orig: vs_battle_applyShieldStats (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies a shield's equipment and gems, then sums base and gem stats, class and affinity values into its current and baseline fields.
pub fn applyShieldStats(target: ?*v.vs_battle_uiShield, source: ?*v.vs_battle_shieldIntermediate) callconv(.c) void {
    const t = target.?;
    const s = source.?;
    var i: usize = 0;

    c.vs_main_memcpy(&t.base, &s.base, @sizeOf(v.vs_battle_uiEquipment));

    i = 0;
    while (i < 3) : (i += 1) {
        c.vs_main_memcpy(&t.gems[i], &s.gems[i], @sizeOf(v.vs_battle_uiEquipment));
    }

    t.wepId = psx.conv(u8, s.base.wepId);
    t.dropRate = s.dropRate;
    t.index = psx.conv(u8, s.index);
    t.base.material = s.material;

    i = 0;
    while (i < 4) : (i += 1) {
        t.types[i] = psx.conv(u8, s.base.types[i]);
    }

    t.currentDp = s.base.currentDp;
    t.maxDp = s.base.maxDp;
    t.currentPp = s.base.currentPp;
    t.maxPp = s.base.maxPp;

    const strSum: c_int = @as(c_int, s.base.strength) +% @as(c_int, s.gems[0].strength) +%
        @as(c_int, s.gems[1].strength) +% @as(c_int, s.gems[2].strength);
    t.baseStr = psx.conv(u16, strSum);
    t.currentStr = psx.conv(i16, t.baseStr);

    const intSum: c_int = @as(c_int, s.base.intelligence) +% @as(c_int, s.gems[0].intelligence) +%
        @as(c_int, s.gems[1].intelligence) +% @as(c_int, s.gems[2].intelligence);
    t.baseInt = psx.conv(u16, intSum);
    t.currentInt = psx.conv(i16, t.baseInt);

    const agiSum: c_int = @as(c_int, s.base.agility) +% @as(c_int, s.gems[0].agility) +%
        @as(c_int, s.gems[1].agility) +% @as(c_int, s.gems[2].agility);
    t.baseAgility = psx.conv(u16, agiSum);
    t.currentAgility = psx.conv(i16, t.baseAgility);

    i = 0;
    while (i < 6) : (i += 1) {
        const sum: c_int = @as(c_int, s.base.classes[i]) +% @as(c_int, s.gems[0].classes[i]) +%
            @as(c_int, s.gems[1].classes[i]) +% @as(c_int, s.gems[2].classes[i]);
        const val = psx.conv(i16, sum);
        t.classAffinityCurrent.class[1][i] = val;
        t.classAffinityCurrent.class[0][i] = val;
        t.classAffinityBaseline.class[i] = val;
    }

    i = 0;
    while (i < 7) : (i += 1) {
        const sum: c_int = @as(c_int, s.base.affinities[i]) +% @as(c_int, s.gems[0].affinities[i]) +%
            @as(c_int, s.gems[1].affinities[i]) +% @as(c_int, s.gems[2].affinities[i]);
        const cur = psx.conv(i16, sum);
        t.classAffinityCurrent.affinity[1][i] = cur;
        t.classAffinityCurrent.affinity[0][i] = cur;
        t.classAffinityBaseline.affinity[i] = psx.conv(u16, cur);
        t.unk134[i] = 0;
    }
}
