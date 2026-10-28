//! Room section setup: marks the section set up and runs its key or sigil effect (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008BEBC (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets up a room section once: runs its key or sigil effect, then its follow-up call; returns 1 if it ran, 0 if already set up.
pub fn func_8008BEBC(arg0: ?*v._mpdRoomSectionA) callconv(.c) c_int {
    const section = arg0.?;
    if (section.unk12 != 0) return 0;

    const temp_a0: c_uint = psx.conv(c_uint, psx.conv(u16, section.keyOrSigil));
    section.unk12 = 1;
    if ((temp_a0 -% 0x1CA) < 7) {
        c.func_8008E6DC(@as(c_int, psx.conv(i16, temp_a0)) -% 0x1CA);
    }
    if (section.unkE == 0) {
        section.unk13 = 8;
        c.func_8008C070(3, psx.cptr(c._mpdRoomSectionA, section));
        return 1;
    }
    _ = c.func_8008BF48(psx.cptr(c._mpdRoomSectionA, section));
    return 1;
}
