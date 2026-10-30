//! Sets the loot list node and clears the loot pointer, then calls func_800CACD0(12, 2) (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CB158 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Sets the current loot list node, clears the loot pointer and calls func_800CACD0(12, 2).
pub fn func_800CB158(node: ?*v.vs_battle_lootListNode) callconv(.c) void {
    psx.put(v.g.D_800EB9C4(), node);
    psx.put(v.g.D_800EB9C8(), null);
    _ = c.func_800CACD0(0xC, 2);
}
