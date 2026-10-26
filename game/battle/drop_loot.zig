//! Loot a defeated enemy leaves behind (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _dropLoot (src/BATTLE/BATTLE.PRG/146C.c)
/// Rolls the enemy's weapon, shield, accessory, armor and misc drops into a new loot node and links it in unless the enemy already has one.
pub fn dropLoot(enemy: ?*v.vs_battle_actor) callconv(.c) void {
    const e = enemy.?;
    const temp_s2: *v.vs_battle_actor2 = psx.get(e.stats).?;

    const raw = c.vs_main_allocHeapR(@sizeOf(v.vs_battle_lootListNode));
    if (raw == null) {
        return;
    }
    const lootList: *v.vs_battle_lootListNode = @ptrCast(@alignCast(raw));

    c.vs_main_bzero(lootList, @as(c_int, @sizeOf(v.vs_battle_lootListNode)));

    lootList.actorId |= c._dropWeaponRand(@ptrCast(&lootList.loot.weapon), @ptrCast(&temp_s2.weapon));
    lootList.actorId |= c._dropShieldRand(@ptrCast(&lootList.loot.shield), @ptrCast(&temp_s2.shield));
    lootList.actorId |= c._dropAccessoryRand(@ptrCast(&lootList.loot.accessory), @ptrCast(&temp_s2.accessory));

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        if (temp_s2.limbs[i].armor.armor.id != 0) {
            lootList.actorId |= c._dropArmorRand(@ptrCast(&lootList.loot.armor[0]), @ptrCast(&temp_s2.limbs[i].armor));
        }
    }

    lootList.actorId |= c._dropMisc(@ptrCast(&lootList.loot), @ptrCast(&temp_s2.miscItem));
    lootList.actorId |= c._dropMiscRand(@ptrCast(&lootList.loot), @ptrCast(&temp_s2.unk960));

    if (lootList.actorId != 0) {
        var node: ?*v.vs_battle_lootListNode = v.g._lootListHead().*;
        var insertLoot: c_int = 1;

        while (node != null) {
            if (node.?.actorId == e.id) {
                insertLoot = 0;
            }
            node = psx.get(node.?.next);
        }

        if (insertLoot != 0) {
            const actorId = e.id;
            const next: ?*v.vs_battle_lootListNode = v.g._lootListHead().*;
            v.g._lootListHead().* = lootList;
            lootList.actorId = actorId;
            psx.put(&lootList.next, next);
            return;
        }
    }

    c.vs_main_freeHeapR(lootList);
}
