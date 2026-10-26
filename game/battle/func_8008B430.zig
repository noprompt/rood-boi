//! Stores the flag record D_800F1BB0 from a 4-byte source (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: func_8008B430 (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies the three flag bytes of `arg0` and `arg1` into D_800F1BB0; clears D_800F1BB6 when all are zero.
pub fn func_8008B430(arg0: ?*v.D_800F4538_unk58_2, arg1: c_int) callconv(.c) void {
    const src = arg0.?;
    if (src.unk0 == 0 and src.unk1 == 0 and src.unk2 == 0 and arg1 == 0) {
        v.g.D_800F1BB6().* = 0;
        return;
    }
    const rec = v.g.D_800F1BB0();
    rec.unk6 = 1;
    rec.unk4 = psx.conv(i16, arg1);
    rec.unk0 = psx.conv(i8, src.unk0);
    rec.unk1 = psx.conv(i8, src.unk1);
    rec.unk2 = psx.conv(i8, src.unk2);
}
