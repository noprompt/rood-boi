//! Swaps the two bytes of the D_80050468 pair: a nonzero `arg0` moves unk0 into unk1 and clears unk0, zero moves unk1 back into unk0 (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007BD3C (src/BATTLE/BATTLE.PRG/146C.c)
/// Exchanges the D_80050468 byte pair in the direction `arg0` selects, then calls the matching hook.
pub fn func_8007BD3C(arg0: c_int) callconv(.c) void {
    const g = v.g.D_80050468();
    if (arg0 != 0) {
        const temp_v1: c_int = g.unk0;
        g.unk0 = 0;
        g.unk1 = psx.conv(u8, temp_v1);
        c.func_800CB560();
        return;
    }
    g.unk0 = g.unk1;
    c.func_800CB550();
}
