//! Offsets and flags for a battle sprite placement, from its table row
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const std = @import("std");
const psx = @import("common").psx;
const v = @import("views_5BF94");

/// orig: func_800CCE10 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Looks up a placement's offsets for `arg0`, mirrors them when bit 2 of `arg1` is set, and subtracts the size terms of `arg2` and `arg3`.
pub fn func_800CCE10(arg0: c_int, arg1: c_int, arg2: c_int, arg3: c_int) callconv(.c) v.func_800CCE10_t {
    const quad = (arg1 >> 2) & 3;
    const sel: usize = @intFromBool(quad == 1 or quad == 2);
    const row = psx.at(v.g.D_800EC284(), arg0);
    const p = &row[sel];

    var offsetX: c_int = psx.getBits(p, "unk0_0");
    const offsetY: c_int = psx.getBits(p, "unk0_12");
    var unk24: c_int = psx.getBits(p, "unk0_24");

    if (((arg1 >> 2) & 1) != 0) {
        offsetX = -%offsetX;
        unk24 ^= 2;
    }

    // The C leaves bits 30..31 of ret uninitialised; they are zeroed here.
    var ret: v.func_800CCE10_t = std.mem.zeroes(v.func_800CCE10_t);
    psx.setBits(&ret, "unk0_0", psx.conv(i12, offsetX -% ((arg2 *% 12 +% 10) >> 1)));
    psx.setBits(&ret, "unk0_12", psx.conv(i12, offsetY -% ((arg3 *% 13 +% 4) >> 1)));
    psx.setBits(&ret, "unk0_24", psx.conv(u2, unk24));
    psx.setBits(&ret, "unk0_26", psx.getBits(p, "unk0_26"));
    return ret;
}
