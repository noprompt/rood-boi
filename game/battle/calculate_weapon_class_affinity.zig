//! Weapon class and affinity totals, summed over the blade and the three gems
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const psx = @import("common").psx;

/// orig: _calculateWeaponClassAffinity (src/BATTLE/BATTLE.PRG/146C.c)
/// Sums each weapon class and affinity over the blade and gems into the weapon's current totals.
pub fn calculateWeaponClassAffinity(arg0: ?*v.vs_battle_actor2) callconv(.c) void {
    const weapon = &arg0.?.weapon;
    const cur = &weapon.classAffinityCurrent;

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        const sum: c_int = @as(c_int, weapon.blade.classes[i]) +%
            @as(c_int, weapon.gems[0].classes[i]) +%
            @as(c_int, weapon.gems[1].classes[i]) +%
            @as(c_int, weapon.gems[2].classes[i]);
        // temp_v0_2 is a short: the sum is truncated to 16 bits before it is stored.
        const temp: i16 = psx.conv(i16, sum);
        cur.class[1][i] = temp;
        cur.class[0][i] = temp;
    }

    i = 0;
    while (i < 7) : (i += 1) {
        const sum: c_int = @as(c_int, weapon.blade.affinities[i]) +%
            @as(c_int, weapon.gems[0].affinities[i]) +%
            @as(c_int, weapon.gems[1].affinities[i]) +%
            @as(c_int, weapon.gems[2].affinities[i]);
        // temp_v0_2 is a short: truncated before the baseline offset is added.
        const temp: i16 = psx.conv(i16, sum);
        cur.affinity[1][i] = temp;
        cur.affinity[0][i] = psx.conv(i16, @as(c_int, temp) +% @as(c_int, weapon.unk168[i]));
    }
}
