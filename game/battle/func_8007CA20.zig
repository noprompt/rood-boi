//! Equips a battle actor's blade and shield weapons (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007CA20 (src/BATTLE/BATTLE.PRG/146C.c)
/// Equips the blade and shield weapons on battle actor `actorId`, if that slot holds an actor.
pub fn func_8007CA20(actorId: c_int, bladeWepId: c_int, shieldWepId: c_int) callconv(.c) void {
    // vs_battle_actors[actorId]: the C does not bounds-check the index.
    const slot = psx.at(v.g.vs_battle_actors(), actorId).*;
    if (slot) |temp| {
        const actor: ?*c.vs_battle_actor = @ptrCast(temp);
        c.func_80077130(actor, actorId, bladeWepId, 0, 0);
        c.func_80077130(actor, actorId, shieldWepId, 1, 0);
    }
}
