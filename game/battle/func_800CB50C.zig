//! Frees the scene message window's text buffer and dismisses its text box
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CB50C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Closes the scene message window if it is open: dismisses text box 7 and frees its buffer.
pub fn func_800CB50C() callconv(.c) void {
    const text = v.g.nameWindowText();
    if (text.* != null) {
        _ = c.vs_battle_dismissTextBox(7);
        c.vs_main_freeHeapR(@ptrCast(text.*));
        psx.put(text, null);
    }
}
