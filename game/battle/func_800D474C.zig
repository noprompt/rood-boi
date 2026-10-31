//! Battle unit 5BF94.c: stores a computed value in the entry's unkA field (src/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D474C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Stores func_800D5198's result in the entry's unkA and returns 1.
pub fn func_800D474C(arg0: ?*v.D_800F53B8_t) callconv(.c) c_int {
    const value = c.func_800D5198(@ptrCast(arg0));
    arg0.?.unkA = value;
    return 1;
}
