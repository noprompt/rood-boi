//! Samples a curve for an entry when its flag is set, else returns the stored value (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D1E2C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns the curve sample for the entry when its unk1_5 flag is set, else its unk2 value.
pub fn func_800D1E2C(arg0: ?*v.D_800F54B8_t) callconv(.c) u8 {
    const entry = arg0.?;
    const value: c_int = if (psx.getBits(entry, "unk1_5") != 0)
        c.vs_battle_sampleCurve(@as(c_int, entry.unk2), @as(c_int, entry.unk0))
    else
        @as(c_int, entry.unk2);
    return psx.conv(u8, value);
}
