//! Menu item table lookup (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

/// orig: vs_battle_getMenuItem (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns menu item slot `id` of the menu item table, with no bounds check.
pub fn getMenuItem(id: c_int) callconv(.c) ?*v.vs_battle_menuItem_t {
    const items = v.g.vs_battle_menuItems().*;
    if (items) |base| return psx.at(base, id);
    // NULL base: C computes NULL + id * sizeof, with the index sign-extended.
    const addr: usize = @bitCast(@as(isize, id) *% @as(isize, @sizeOf(v.vs_battle_menuItem_t)));
    return @ptrFromInt(addr);
}
