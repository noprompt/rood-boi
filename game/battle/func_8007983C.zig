//! Battle frame step: runs the per-frame updates unless the battle state at
//! func_800CB66C() is already in state 1 or func_800CB45C() reports nonzero
//! (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007983C (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the frame's update steps when the battle state is not 1 and the check at func_800CB45C is clear.
pub fn func_8007983C() callconv(.c) void {
    c.func_800C97BC();
    const ability: *v.D_800F18EC_t = @ptrCast(@alignCast(c.func_800CB66C().?));
    if (psx.conv(c_int, ability.unk0) != 1 and c.func_800CB45C() == 0) {
        c.func_8006C40C();
        c.func_800CB114();
        c.func_800CB50C();
        c.func_8006F89C();
    }
}
