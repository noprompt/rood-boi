//! Tests whether the battle room's section 14 pointer is null (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: func_8008E470 (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 when the battle room's section 14 guest address is zero, else 0.
pub fn func_8008E470() callconv(.c) c_int {
    const raw: c_uint = psx.rawOf(v.g.vs_battle_roomData().section14);
    return @intFromBool(raw < 1);
}
