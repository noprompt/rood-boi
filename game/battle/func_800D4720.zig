//! Stores func_800D5198's result in the record's unkA (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D4720 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Stores func_800D5198's result in the record's unkA and returns 0.
pub fn func_800D4720(arg0: ?*v.D_800F53B8_t) callconv(.c) c_int {
    const result: u16 = c.func_800D5198(@ptrCast(arg0));
    arg0.?.unkA = result;
    return 0;
}
