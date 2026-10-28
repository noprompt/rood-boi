//! Forwards battle actor slot's unk44 record to func_800AE4FC (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007C8A4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_800AE4FC with the unk44 record of battle actor `slot`, for slots below 16 that are set.
pub fn func_8007C8A4(slot: c_int, arg1: c_int) callconv(.c) void {
    // The C reads vs_battle_actors[slot] before testing slot < 16: no bounds check.
    const actor = psx.at(v.g.vs_battle_actors(), slot).*;
    if (actor != null and slot < 16) {
        c.func_800AE4FC(@ptrCast(psx.get(actor.?.unk44)), arg1);
    }
}
