//! Stores a 16-bit value in the unkD1C.unk3A field of a BATTLE record (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");

/// orig: func_800CF484 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Stores the low 16 bits of `value` in the record's unkD1C.unk3A field.
pub fn func_800CF484(arg0: c_int, arg1: ?*v.D_800F53B8_t) callconv(.c) void {
    arg1.?.unkD1C.unk3A = psx.conv(i16, arg0);
}
