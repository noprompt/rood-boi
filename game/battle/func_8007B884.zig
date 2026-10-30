//! Battle frame tail: runs the per-frame battle updates unless the battle state is 1
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007B884 (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the battle frame tail: the wait update, then the flagged updates, unless the battle state is 1.
pub fn func_8007B884() callconv(.c) void {
    c.func_800C97BC();
    const ability: *v.D_800F18EC_t = @alignCast(@ptrCast(c.func_800CB66C().?));
    if (@as(c_int, ability.unk0) != 1) {
        if (v.g.D_800F1864().* != 0) {
            c.func_8007B470();
        }
        c.func_800CB114();
        if (v.g.D_800F1860().* != 0) {
            c.func_8007B4C4();
        } else {
            c.func_8007B508();
        }
    }
}
