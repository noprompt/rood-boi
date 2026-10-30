//! Stores two battle counts and a flag, then runs func_80090A1C over a table of records
//! (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008F29C (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores arg1 as a byte and arg0 as two halfwords, then calls func_80090A1C on each of the first arg0 records of D_800F1DD4.
pub fn func_8008F29C(arg0: c_int, arg1: c_int) callconv(.c) void {
    var i: c_int = 0;
    // The record pointer is kept as an address so that `++var_s1` advances by the record size, as in C.
    var s1: usize = @intFromPtr(v.g.D_800F1DD4().*);
    v.g.D_800F1DCA().* = psx.conv(u8, arg1);
    v.g.D_800F1DC2().* = psx.conv(i16, arg0);
    v.g.D_800F1DC0().* = psx.conv(i16, arg0);

    while (i < arg0) : (i +%= 1) {
        c.func_80090A1C(@as([*c]c.D_800F1DD4_t, @ptrFromInt(s1)));
        s1 +%= @sizeOf(v.D_800F1DD4_t);
    }
}
