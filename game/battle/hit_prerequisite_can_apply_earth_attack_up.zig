//! Earth attack-up hit prerequisite: the target has no effect 23 and wields a weapon with a blade (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _hitPrerequisiteCanApplyEarthAttackUp (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when effect 23 does not apply to the actor in slot `*arg1` and its weapon has a blade, else 0.
pub fn hitPrerequisiteCanApplyEarthAttackUp(_: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    if (c._hitPrerequisiteCanApplyEffect(23, arg1) == 0) {
        // The C does not check the slot index against the array length.
        const slot = psx.at(v.g.vs_battle_actors(), arg1[0]).*;
        const actor = psx.get(slot.?.stats).?;
        if (actor.weapon.blade.id != 0) {
            return 1;
        }
    }
    return 0;
}
