//! Battle per-frame step: runs three update calls unless the state at func_800CB66C's unk0 is 1
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_800797BC (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the frame's first update, then the three follow-up steps unless the current state's first field is 1.
pub fn func_800797BC() callconv(.c) void {
    c.func_800C97BC();
    const raw = c.func_800CB66C().?;
    const state: *v.D_800F18EC_t = @ptrFromInt(@intFromPtr(raw));
    if (state.unk0 != 1) {
        c.func_8006C40C();
        c.func_800CB114();
        c.func_8006F89C();
    }
}
