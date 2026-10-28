//! Battle state reset: action index, camera mode and two follow-up calls (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");
const v = @import("views_146C");

/// orig: func_800704D8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets the battle's mode and action index, then runs the character-state and follow-up routines.
pub fn func_800704D8() callconv(.c) void {
    v.g.D_800F196C().* = 5;
    v.g.D_800F19CC().*.?.unk8.actionIndex = 0;
    v.g._cameraMode().* = 1;
    c.func_800CB660((v.g.vs_battle_characterState().*.?.weaponDrawn & 1) | 2);
    c.func_800CAB40();
    c.func_8006C39C();
}
