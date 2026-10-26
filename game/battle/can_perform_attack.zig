//! Whether an action's hit may land: runs the hit's prerequisite check (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: _canPerformAttack (src/BATTLE/BATTLE.PRG/146C.c)
/// Checks hit `hitNumber` of `action` against its prerequisite function, which decides whether the attack can be performed.
pub fn canPerformAttack(action: ?*v.vs_action_t, arg1: [*c]u8, hitNumber: c_int) callconv(.c) c_int {
    const act = action.?;
    // hitParams is indexed without a check, as the C does: hitNumber is not bounded.
    const hit = psx.at(&act.hitParams, hitNumber);
    const prereq: usize = psx.getBits(hit, "prerequisiteFunction");

    if (hitNumber != 0) {
        if (prereq == 1 and arg1[3] == 4) {
            return 0;
        }
    }

    const Prerequisite = *const fn (?*v.vs_action_t, [*c]u8) callconv(.c) c_int;
    const table = v.g._attackPrerequisiteFunctions();
    const f: Prerequisite = @ptrCast(table[prereq].?);
    return f(action, arg1);
}
