//! Whether an item id is held in the inventory, returning the count for misc items
//! (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: vs_battle_itemIdIsInInventory (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns 1 for id 0, else the item's count for a misc item, 1 for a blade, grip, armor or gem held, else 0.
pub fn itemIdIsInInventory(id: c_int) callconv(.c) c_int {
    if (id == 0) return 1;

    const inv = v.g.vs_main_inventory();
    const sizes = v.g._itemCategorySizes();

    // Category index: the first category whose size exceeds id (unsigned compare, as the object does).
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        if (psx.conv(c_uint, id) < sizes[i]) break;
    }

    var ret: c_int = 0;
    if (i < 8) {
        switch (i) {
            0 => {
                var k: usize = 0;
                while (k < 16) : (k += 1) {
                    if (@as(c_int, inv.blades[k].id) == id) {
                        ret = 1;
                        break;
                    }
                }
            },
            1 => {
                var k: usize = 0;
                while (k < 16) : (k += 1) {
                    if (@as(c_int, inv.grips[k].id) == id) {
                        ret = 1;
                        break;
                    }
                }
            },
            2 => {
                var k: usize = 0;
                while (k < 16) : (k += 1) {
                    if (@as(c_int, inv.armor[k].id) == id) {
                        ret = 1;
                        break;
                    }
                }
            },
            4 => {
                var k: usize = 0;
                while (k < 48) : (k += 1) {
                    if (@as(c_int, inv.gems[k].id) == id) {
                        ret = 1;
                        break;
                    }
                }
            },
            5, 6, 7 => {
                var k: usize = 0;
                while (k < 64) : (k += 1) {
                    if (@as(c_int, inv.misc[k].id) == id and inv.misc[k].count != 0) {
                        ret = @as(c_int, inv.misc[k].count);
                        break;
                    }
                }
            },
            // Category 3 has no case in the original: ret stays 0.
            else => {},
        }
    }
    return ret;
}
