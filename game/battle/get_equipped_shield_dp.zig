//! Shield power of the target's equipped shield, read from the target actor's stats (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: _getEquippedShieldDp (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the current PP of the shield the hit's target actor has equipped.
pub fn getEquippedShieldDp(_: ?*v.vs_action_t, arg1: ?*v._hitEntity_t, _: ?*v._hitEntity_t, _: c_int, _: c_int) callconv(.c) c_short {
    const target: usize = arg1.?.unk0.targetActor;
    const actor = psx.get(v.g.vs_battle_actors()[target].?.stats).?;
    return psx.conv(c_short, actor.shield.currentPp);
}
