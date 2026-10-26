//! Copies the two words of a battle record into D_800F1A30 (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: func_8007DDB8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies the record's first two words into the global pair D_800F1A30.
pub fn func_8007DDB8(arg0: ?*v.D_800F1A68_t) callconv(.c) void {
    const dst = v.g.D_800F1A30();
    dst[0] = arg0.?.unk0;
    dst[1] = arg0.?.unk4;
}
