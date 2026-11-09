//! Links a battle actor into the actor list behind slot 0 (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: _insertActor (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Links `actor` in after slot 0 of the battle actor list unless it is already linked; returns 1 when it links.
pub fn insertActor(actor: ?*v.vs_battle_actor) callconv(.c) c_int {
    const a = actor.?;
    if ((@as(c_int, a.allegiance) & 7) != 0 and a.id != 0) {
        const slots = v.g.vs_battle_actors();
        var i: usize = 0;
        while (i < 16) : (i += 1) {
            if (slots[i] != null and slots[i].?.next == a) {
                return 0;
            }
        }

        // The C repeats the id test above; kept as written.
        if (a.id != 0) {
            a.next = slots[0].?.next;
            slots[0].?.next = a;
        } else {
            a.next = null;
        }

        return 1;
    }

    return 0;
}
