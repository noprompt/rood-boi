//! Battle frame step: runs the 146C.c update chain when the current entity is live and no
//! blocking state is set (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007B938 (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the per-frame update chain unless the current entry is marked inactive or the blocking check is set.
pub fn func_8007B938() callconv(.c) void {
    c.func_800C97BC();
    // The C dereferences the result unconditionally: a null pointer traps here.
    const entry: *v.D_800F18EC_t = @ptrCast(@alignCast(c.func_800CB66C().?));
    if (entry.unk0 != 1 and c.func_800CB45C() == 0) {
        c.func_8007B470();
        c.func_800CB114();
        c.func_800CB50C();
        c.func_8007B508();
    }
}
