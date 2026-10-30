//! Runs a pending block-8 text for slot `arg0` through func_800CE83C, then clears its pending bit
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CEF74 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Hands slot `arg0`'s pending text to func_800CE83C once and clears its pending bit; returns the status of func_800CEEBC.
pub fn func_800CEF74(arg0: c_int) callconv(.c) c_int {
    // unk24 is never written here: it is uninitialised in the original too.
    var sp10: v.D_800F53B8_t2 = undefined;

    c.func_800D7890(1);
    const result = c.func_800CEEBC();
    if (result != 0) {
        // The shift count is masked to 5 bits, as the x86 object does for an out-of-range arg0.
        const bit: c_uint = @as(c_uint, 1) << @as(u5, @truncate(psx.conv(c_uint, arg0)));
        const flags = v.g.D_800F521C();
        if ((flags.* & bit) != 0) {
            const a1 = psx.get(v.g.D_800F569C().*.?.block8Data);
            sp10.unk18 = arg0 *% 3;
            psx.put(&sp10.unk0, v.g.D_800F5234());
            psx.put(&sp10.unk4, v.g.D_800F5234());
            sp10.unk10 = 0;
            psx.put(&sp10.unk8, psx.byteAt(v.D_800F53B8_t3, v.g.D_800F5234(), 0xC));
            psx.put(&sp10.unkC, psx.byteAt(v.D_800F53B8_t3, v.g.D_800F5234(), 0xC));
            psx.put(&sp10.unk1C, null);
            sp10.unk20 = v.g.D_800F5318().*;
            psx.put(&sp10.unk14, a1);
            _ = c.func_800CE83C(psx.cptr(c.D_800F53B8_t2, &sp10));
            c.func_800CF478(4);
            v.g.D_800F5228().* +%= 1;
            flags.* &= ~bit;
        }
    }
    return result;
}
