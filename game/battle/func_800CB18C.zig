//! Loot handoff: stores the loot pointer and clears the loot list head (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CB18C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Sets the current loot pointer, clears the loot list head and runs func_800CACD0(12, 2).
pub fn func_800CB18C(loot: ?*v.vs_battle_loot) callconv(.c) void {
    v.g.D_800EB9C8().* = loot;
    v.g.D_800EB9C4().* = null;
    _ = c.func_800CACD0(0xC, 2);
}
