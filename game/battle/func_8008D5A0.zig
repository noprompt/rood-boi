//! Sets the flag at D_800F1D68 from the argument and, when the current room has a section 12, calls func_8008E4DC (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008D5A0 (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores `flag` in D_800F1D68 when the room's section 12 holds at least one 184-byte entry, calling func_8008E4DC with it.
pub fn func_8008D5A0(flag: c_int) callconv(.c) void {
    if (v.g.vs_battle_roomData().header.section12Len / 184 != 0) {
        if (flag != 0) {
            c.func_8008E4DC(1);
        } else {
            c.func_8008E4DC(0);
        }
        v.g.D_800F1D68().* = psx.conv(i16, flag);
    }
}
