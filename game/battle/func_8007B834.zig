//! Calls the 146C battle setup steps and runs the rest only while the
//! D_800F18EC state's first byte is not 1 (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007B834 (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the setup step, then the follow-up steps unless the state's unk0 is 1.
pub fn func_8007B834() callconv(.c) void {
    c.func_800C97BC();
    const state: *align(1) v.D_800F18EC_t = @ptrCast(c.func_800CB66C().?);
    if (state.unk0 != 1) {
        c.func_8007B470();
        c.func_800CB114();
        c.func_8007B764();
    }
}
