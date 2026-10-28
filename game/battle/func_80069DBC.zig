//! Clears the 146C counter and its record table (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80069DBC (src/BATTLE/BATTLE.PRG/146C.c)
/// Zeroes D_80060064 and the four-entry record table at D_80061078.
pub fn func_80069DBC() callconv(.c) void {
    v.g.D_80060064().* = 0;
    c.vs_main_bzero(@ptrCast(v.g.D_80061078()), @intCast(@sizeOf([4]v.D_80061078_t)));
}
