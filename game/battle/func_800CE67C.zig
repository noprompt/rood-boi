//! Resets the battle state variables of unit 5BF94 (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CE67C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Calls func_800CF478(0), then clears the battle state variables and the four-entry table D_800F5320.
pub fn func_800CE67C() callconv(.c) void {
    c.func_800CF478(0);
    v.g.D_800F5228().* = 0;
    v.g.D_800F5224().* = 0;
    v.g.D_800F54A8().* = 0;
    v.g.D_800F5318().* = 0;
    psx.put(v.g.D_800F54B0(), null);
    psx.put(v.g.D_800F53BC(), null);
    v.g.D_800F53B4().* = 0;
    psx.put(v.g.D_800F53B8(), null);
    v.g.D_800F5330()[0] = 0;
    v.g.D_800F522C().* = 0;
    psx.put(v.g.D_800F5218(), null);
    var i: c_int = 0;
    while (i < 4) : (i +%= 1) {
        v.g.D_800F5320()[@as(usize, @intCast(i))] = 0;
    }
}
