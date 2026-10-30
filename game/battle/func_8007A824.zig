//! Forwards a pointer 0x2084 bytes into the block at D_800F1870 to func_800C64D0 (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007A824 (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_800C64D0 with the address 0x2084 bytes past D_800F1870 and the given pointer.
pub fn func_8007A824(arg0: [*c]c_int) callconv(.c) void {
    const base: usize = @intFromPtr(v.g.D_800F1870().*);
    const p: [*c]c_uint = @ptrFromInt(base +% 0x2084);
    c.func_800C64D0(p, @ptrCast(arg0));
}
