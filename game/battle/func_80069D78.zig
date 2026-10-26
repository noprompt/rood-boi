//! First-person view bookkeeping in battle (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80069D78 (src/BATTLE/BATTLE.PRG/146C.c)
/// Syncs the camera angles from the position, then copies the first-person view flag into bit 16 of the scratch facing.
pub fn func_80069D78() callconv(.c) void {
    _ = c.vs_battle_syncCameraAnglesFromPosition(null);
    const scratch = v.g.vs_scratch();
    const enabled: u32 = @bitCast(v.g._firstPersonViewEnabled().*);
    scratch.firstPersonViewFacing = (scratch.firstPersonViewFacing & 0x7FFF) | (enabled << 0x10);
}
