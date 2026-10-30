//! Battle state step: the key-or-sigil gate, then the state flag or the room callback (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_800744B8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Advances the battle state one step; returns 1 while the step is not finished, 0 when it is.
pub fn func_800744B8() callconv(.c) c_int {
    if (psx.get(v.g.D_800F1910().unk0).?.keyOrSigil != 0) {
        if (c.func_800CB45C() != 0) return 1;
        c.func_8006C40C();
        return 0;
    }
    c.func_800C97BC();
    const temp: *align(1) v.D_800F18EC_t = @ptrCast(c.func_800CB66C().?);
    if (temp.unk0 == 1) return 1;
    if (temp.unk2 != 0) {
        c.vs_battle_setStateFlag(
            psx.conv(c_short, @as(c_int, psx.get(v.g.D_800F1910().unk0).?.unk10) +% 0x3C0),
            1,
        );
    } else {
        c.func_8008D5FC(psx.cptr(c._mpdRoomSectionA, psx.get(v.g.D_800F1910().unk0).?));
    }
    c.func_800CB114();
    c.func_8006C40C();
    return 0;
}
