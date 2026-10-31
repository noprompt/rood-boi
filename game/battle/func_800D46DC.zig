//! Advances an entry's `unkA` field, or sets it from `func_800D5198` (src/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D46DC (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Sets `unkA` of the entry from `func_800D5198` when `arg0` is nonzero, else adds 2 to it.
pub fn func_800D46DC(arg0: c_int, arg1: ?*v.D_800F53B8_t) callconv(.c) void {
    if (arg0 != 0) {
        const value = c.func_800D5198(@ptrCast(arg1));
        arg1.?.unkA = value;
    } else {
        arg1.?.unkA +%= 2;
    }
}
