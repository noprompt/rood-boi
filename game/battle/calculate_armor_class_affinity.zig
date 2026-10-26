//! Copies a limb armor's class and affinity baselines into its current values
//! (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: _calculateArmorClassAffinity (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets a limb's current armor class and affinity values from its armor and its unk88 modifiers.
pub fn calculateArmorClassAffinity(actor: ?*v.vs_battle_actor2, limbIndex: c_int) callconv(.c) void {
    const limb = psx.at(&actor.?.limbs, limbIndex);
    const armor = &limb.armor;

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        const value: u16 = psx.conv(u16, armor.armor.classes[i]);
        armor.classAffinityCurrent.class[1][i] = psx.conv(i16, value);
        armor.classAffinityCurrent.class[0][i] = psx.conv(i16, value);
    }

    i = 0;
    while (i < 7) : (i += 1) {
        const value: u16 = psx.conv(u16, armor.armor.affinities[i]);
        armor.classAffinityCurrent.affinity[1][i] = psx.conv(i16, value);
        const modified: c_int = @as(c_int, value) +% @as(c_int, armor.unk88[i]);
        armor.classAffinityCurrent.affinity[0][i] = psx.conv(i16, modified);
    }
}
