//! Activates a room section and its paired section, then runs the common tail (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008BF48 (src/BATTLE/BATTLE.PRG/146C.c)
/// Plays the section's sounds, locks it, locks the paired section when it has one, then runs the common tail.
pub fn func_8008BF48(arg0: ?*v._mpdRoomSectionA) callconv(.c) c_int {
    const section = arg0.?;

    if (section.unkE == 0) {
        c.vs_main_playSfxDefault(0x7E, 0x1D);
        c.vs_main_playSfxDefault(0x7E, 0x1E);
    } else {
        c.vs_main_playSfxDefault(0x7E, 0x16);
        c.vs_main_playSfxDefault(0x7E, 0x17);
    }
    _ = c.func_8009291C(@as(c_int, section.unk0.unk8.lock.unk1));
    if (section.unkE != 0) {
        c.func_8008BD74(psx.cptr(c._mpdRoomSectionA, section));
    }
    if (section.unk10 != -1) {
        const temp_s0 = psx.get(v.g.vs_battle_roomData().sectionA).?;
        // The index is re-read from the section at each use, as the C re-reads it after calls.
        if (psx.at(temp_s0, section.unk10).unk0.unkA != 0) {
            _ = c.func_8009291C(@as(c_int, psx.at(temp_s0, section.unk10).unk0.unk8.lock.unk1));
            if (psx.at(temp_s0, section.unk10).unkE != 0) {
                c.func_8008BD74(psx.cptr(c._mpdRoomSectionA, psx.at(temp_s0, section.unk10)));
            }
            psx.at(temp_s0, section.unk10).unk12 = 1;
        }
    }
    c.func_8008C070(1, psx.cptr(c._mpdRoomSectionA, section));
    return 1;
}
