//! Main menu disc position (pc/src/game/BATTLE/BATTLE.PRG/6F014.c).
/// orig: vs_battle_getMainMenuLba (pc/src/game/BATTLE/BATTLE.PRG/6F014.c)
/// Returns the disc LBA of the main menu's program file.
pub fn getMainMenuLba() callconv(.c) c_int {
    return 85000;
}
