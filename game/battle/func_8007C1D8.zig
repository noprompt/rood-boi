//! Sets the allegiance state of a battle actor slot (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: func_8007C1D8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the state of battle actor slot `index` to 4 when `keep` is nonzero, else to 8; empty slots are left alone.
pub fn func_8007C1D8(index: c_int, keep: c_int) callconv(.c) void {
    // The C does not bound-check the slot index: psx.at computes the element address as the C does.
    const slot = psx.at(v.g.vs_battle_actors(), index);
    if (slot.*) |actor| {
        if (keep != 0) {
            actor.allegiance = 4;
            return;
        }
        actor.allegiance = 8;
    }
}
