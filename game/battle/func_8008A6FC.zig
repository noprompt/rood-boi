//! Frees the loot list and empties it (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008A6FC (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Frees every node of the loot list and clears the list head.
pub fn func_8008A6FC() callconv(.c) void {
    var node: ?*align(4) v.vs_battle_lootListNode = v.g._lootListHead().*;
    while (node) |n| {
        const next = n.next;
        c.vs_main_freeHeapR(n);
        node = next;
    }
    v.g._lootListHead().* = null;
}
