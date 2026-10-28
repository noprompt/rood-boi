//! Looks up the room section for the position that func_800A1108 reports
//! (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_800748B8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the room section at the position from func_800A1108, or null when its height is outside the section's band.
pub fn func_800748B8(arg0: c_int) callconv(.c) ?*v._mpdRoomSectionA {
    // uninitialised in the original until func_800A1108 and func_80074798 fill them
    var sp10: v.func_8006EBF8_t = undefined;
    var sp20: [4]u8 = undefined;

    _ = c.func_800A1108(arg0, @ptrCast(&sp10));
    _ = c.func_80074798(@ptrCast(&sp10), &sp20[0]);

    // the section lookup runs before the height test, as in the original
    var temp_s1: ?*v._mpdRoomSectionA = @ptrCast(c.func_8008BC04(
        @as(c_int, sp20[0]),
        @as(c_int, sp20[2]),
        @as(c_int, sp20[1]),
    ));

    const x: c_int = (@as(c_int, sp20[0]) << 7) | 0x40;
    const z: c_int = (@as(c_int, sp20[2]) << 7) | 0x40;
    const dist: c_short = c.func_8008DC7C(x, z);
    // sign-extend the low 15 bits of the 16-bit result
    const wide: c_int = (@as(c_int, dist) << 17) >> 17;
    const diff: c_int = wide -% @as(c_int, sp10.unk0.unk4.vy);
    const band: c_int = diff +% 0x3F;
    if (psx.conv(c_uint, band) >= 0x7F) {
        temp_s1 = null;
    }
    return temp_s1;
}
