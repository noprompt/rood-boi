//! Looks up the room section at the current position and returns its value (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008A4FC (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the value of the room section at the current position, or 0 when none applies.
pub fn func_8008A4FC() callconv(.c) c_int {
    var sp10: v.func_8006EBF8_t = undefined;
    _ = c.func_800A1108(0, &sp10);

    const temp_v0_2: c_uint = psx.conv(c_uint, c.func_800A0BE0(0));
    const temp_a2: c_uint = temp_v0_2 & 0x70000;
    const s0: *v.func_8006EBF8_t_fields = &sp10.unk0.unk0.fields;

    const var_a0: c_int = if (temp_a2 != 0) 0 else @as(c_int, psx.getBits(s0, "unk0_0"));
    const var_a1: c_int = if (temp_a2 != 0) 0 else @as(c_int, psx.getBits(s0, "unk0_16"));
    const var_a2: c_uint = if (temp_a2 != 0) temp_a2 >> 16 else @as(c_uint, psx.getBits(s0, "unk0_8"));

    // func_8008B764(u_int, u_int, int): the first two ints are converted to unsigned, the third unsigned to int.
    // func_8008B764(...)->unk0_16 & 1: bit 16 of the struct's first word, i.e. byte 2 bit 0 (little endian).
    const sec3 = c.func_8008B764(
        psx.conv(c_uint, var_a0),
        psx.conv(c_uint, var_a1),
        psx.conv(c_int, var_a2),
    ).?;
    const flagByte: *align(1) u8 = @ptrFromInt(@intFromPtr(sec3) + 2);

    if ((flagByte.* & 1) != 0 and (temp_v0_2 & 0x504000) == 0) {
        // The section lookup reads the fields again: the C re-reads them after the calls above.
        const room: ?*v._mpdRoomSection9 = @ptrCast(c.func_8008D438(
            @as(c_int, psx.getBits(s0, "unk0_0")),
            @as(c_int, psx.getBits(s0, "unk0_16")),
            @as(c_int, psx.getBits(s0, "unk0_8")),
        ));
        if (room) |r| {
            if (r.unk6 == 16) {
                return @as(c_int, r.unkA);
            }
        }
    }
    return 0;
}
