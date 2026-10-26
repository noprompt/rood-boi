//! Frees the loot list and empties it (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008A6FC (src/BATTLE/BATTLE.PRG/146C.c)
/// Frees every node of the loot list and clears the list head.
pub fn func_8008A6FC() callconv(.c) void {
    var node: ?*v.vs_battle_lootListNode = v.g._lootListHead().*;
    while (node) |n| {
        const next = psx.get(n.next);
        c.vs_main_freeHeapR(n);
        node = next;
    }
    v.g._lootListHead().* = null;
}
