//! Copies the battle camera and clip settings into a D_800F54D8 block (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D1B18 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Fills the camera block with the battle camera's position, look-at point, roll, clip planes and far clip.
pub fn func_800D1B18(arg0: ?*v.D_800F54D8_t) callconv(.c) void {
    const out = arg0.?;
    c.vs_battle_getCameraPosition(psx.cptr(c.VECTOR, &out.position));
    c.vs_battle_getCameraLookAt(psx.cptr(c.VECTOR, &out.lookAt));
    out.roll = c.vs_battle_getCameraRoll() +% 4096 * 8;
    out.nearClip = v.g.vs_main_nearClip().*;
    out.projectionDistance = v.g.vs_main_projectionDistance().*;
    out.farClip = v.g.vs_scratch().camera.farClip;
}
