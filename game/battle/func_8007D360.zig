//! Clears the battle's per-frame render and colour state (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007D360 (src/BATTLE/BATTLE.PRG/146C.c)
/// Resets the battle's scalar, colour and vector state to their defaults.
pub fn func_8007D360() callconv(.c) void {
    v.g.D_800F1B98().* = 0;
    v.g.D_800F1B9C().* = 0;
    v.g.D_800F1A20().* = 0;
    v.g.D_800F1A28()[0] = 0;
    v.g.D_800F1A28()[1] = 0;
    v.g.D_800F1A28()[2] = 0;
    v.g.D_800F1A30()[0] = 0x1000;
    v.g.D_800F1A30()[1] = 0x1000;
    v.g.D_800F1A30()[2] = 0;
    v.g.D_800F1A78().r0 = 0x80;
    v.g.D_800F1A78().g0 = 0x80;
    v.g.D_800F1A78().b0 = 0x80;
    v.g.D_800F1A9C()[0] = 0x80;
    v.g.D_800F1A9C()[1] = 0x80;
    v.g.D_800F1A9C()[2] = 0x80;
    v.g.D_800F1A68().unk0 = 0;
    v.g.D_800F1A68().unk4 = 0;
    v.g.D_800F1A68().unk8 = 0;
    v.g.D_800F1A44().* = 0;
    v.g.D_800F1A40().* = 0;
}
