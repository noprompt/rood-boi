//! Toggles a room section's state, clears its timer byte and sets the matching
//! section-3 flag (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008D658 (src/BATTLE/BATTLE.PRG/146C.c)
/// Plays the toggle sounds for a room section, flips its state and sets the flag of the section it finds.
pub fn func_8008D658(section: ?*v._mpdRoomSectionA) callconv(.c) void {
    const room = section.?;

    if (room.unk0.unk8.s16 == 0) {
        _ = c.vs_main_playSfxDefault(0x7E, 0x3B);
        _ = c.vs_main_playSfxDefault(0x7E, 0x3C);
    } else {
        _ = c.vs_main_playSfxDefault(0x7E, 0x3D);
        _ = c.vs_main_playSfxDefault(0x7E, 0x3E);
    }
    _ = c.func_8009291C(@as(c_int, room.unk0.unk6));
    room.unk0.unkB = 0;
    room.unk0.unk8.s16 = @as(i16, @intFromBool(room.unk0.unk8.s16 == 0));
    const temp: ?*v._mpdRoomSection3 = @ptrCast(c.func_8008B764(
        psx.conv(c_uint, room.unk0.unk0),
        psx.conv(c_uint, room.unk0.unk2),
        psx.conv(c_int, room.unk0.unk4),
    ));
    if (temp) |t| {
        psx.setBits(t, "unk0_10", psx.conv(u3, @as(c_int, room.unk0.unk8.s16) *% 5));
    }
}
