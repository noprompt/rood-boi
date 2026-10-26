//! Sets the battle camera's per-mode value in the battle state (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: func_8006EF10 (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores 0x600 or 0x900 in the battle state's unk2C0C by the camera's delta mode (modes 0-3).
pub fn func_8006EF10() callconv(.c) void {
    const mode: c_int = v.g.vs_battle_cameraCurrentSpherical().delta.mode;
    switch (mode) {
        0, 1 => v.g.D_800F19CC().*.?.unk2C0C = 0x600,
        2, 3 => v.g.D_800F19CC().*.?.unk2C0C = 0x900,
        else => {},
    }
}
