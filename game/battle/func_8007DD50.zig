//! Arms the D_800F1B98 state and allocates the D_800F1ABC block on first use (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007DD50 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets state 1 and allocates the D_800F1ABC block if it is missing, or sets state 3 when `arg0` is zero.
pub fn func_8007DD50(arg0: c_int) callconv(.c) void {
    if (arg0 != 0) {
        v.g.D_800F1B98().* = 1;
        if (psx.get(v.g.D_800F1ABC().*) == null) {
            const raw = c.vs_main_allocHeapR(@as(c_uint, @sizeOf(v.D_800F1ABC_t)));
            const block: ?*v.D_800F1ABC_t = if (raw) |p| @ptrCast(@alignCast(p)) else null;
            psx.put(v.g.D_800F1ABC(), block);
            c.func_8007D41C();
        }
    } else {
        v.g.D_800F1B98().* = 3;
    }
}
