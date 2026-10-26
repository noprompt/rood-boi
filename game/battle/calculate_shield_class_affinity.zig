//! Derives the shield's current class and affinity tables from its base and gems
//! (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: _calculateShieldClassAffinity (src/BATTLE/BATTLE.PRG/146C.c)
/// Sums the classes and affinities of the shield's base and three gems into its current class-affinity table.
pub fn calculateShieldClassAffinity(arg0: ?*v.vs_battle_actor2) callconv(.c) void {
    const actor = arg0.?;
    const shield = &actor.shield;

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        const sum: c_int = @as(c_int, shield.base.classes[i]) +%
            @as(c_int, shield.gems[0].classes[i]) +%
            @as(c_int, shield.gems[1].classes[i]) +%
            @as(c_int, shield.gems[2].classes[i]);
        const temp: i16 = psx.conv(i16, sum);
        shield.classAffinityCurrent.class[1][i] = temp;
        shield.classAffinityCurrent.class[0][i] = temp;
    }

    i = 0;
    while (i < 7) : (i += 1) {
        const sum: c_int = @as(c_int, shield.base.affinities[i]) +%
            @as(c_int, shield.gems[0].affinities[i]) +%
            @as(c_int, shield.gems[1].affinities[i]) +%
            @as(c_int, shield.gems[2].affinities[i]);
        const temp: i16 = psx.conv(i16, sum);
        shield.classAffinityCurrent.affinity[1][i] = temp;
        shield.classAffinityCurrent.affinity[0][i] =
            psx.conv(i16, @as(c_int, temp) +% @as(c_int, shield.unk134[i]));
    }
}
