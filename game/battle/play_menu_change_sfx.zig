//! Menu change sound effect (pc/src/game/BATTLE/BATTLE.PRG/573B8.c).
const c = @import("c_573B8");

/// orig: vs_battle_playMenuChangeSfx (pc/src/game/BATTLE/BATTLE.PRG/573B8.c)
/// Plays the default menu change sound effect (0x7E, 4).
pub fn playMenuChangeSfx() callconv(.c) void {
    c.vs_main_playSfxDefault(0x7E, 4);
}
