//! Installs an actor into a battle slot and sets up its state (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_800773BC (src/BATTLE/BATTLE.PRG/146C.c)
/// Puts `actor` into battle slot `slot`, runs its setup calls and links it into the actor chain.
pub fn func_800773BC(actor: ?*v.vs_battle_actor, slot: c_int, arg2: c_int, arg3: c_int, arg4: c_int, arg5: c_int) callconv(.c) void {
    _ = c.func_800A0204(slot, 0, 0, 0);
    c.func_800A087C(slot, 0x1847);
    psx.at(v.g.vs_battle_actors(), slot).* = actor;
    c.func_80076D50(psx.conv(c_uint, slot), arg2, arg3, arg4, arg5);
    c.func_800A0AFC(slot, 0x9000, 0x12000);
    c.func_8009DF3C(slot, 0);

    const a = actor.?;
    if ((@as(c_int, a.allegiance) & 7) != 0) {
        if (slot != 0) {
            a.next = v.g.vs_battle_actors()[0].?.next;
            psx.put(&v.g.vs_battle_actors()[0].?.next, a);
        } else {
            psx.put(&a.next, null);
        }
    }
    if ((a.weaponDrawn & 1) != 0) {
        c.func_800A087C(slot, 0x1846);
    } else {
        c.func_800A087C(slot, 0x46);
    }
    a.unk38 = 0;
    _ = c.func_800E6178(@ptrCast(actor), -1);
}
