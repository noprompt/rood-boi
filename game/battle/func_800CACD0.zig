//! Opens the battle menu on a shortcut or menu change, setting up its item buffers and menu flags once (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CACD0 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Opens the battle menu into `menuState` when the menu is idle; otherwise plays the invalid sound.
pub fn func_800CACD0(menuState: c_int, arg1: c_int) callconv(.c) c_int {
    if (v.g.vs_battle_menuState().currentMenu == 0x3F) {
        v.g.vs_battle_shortcutInvoked().* = 0;
        v.g.D_800F4FDB().* = 0;
        v.g.D_800F4EA0().* = c.func_800CABE0(arg1);
        v.g.D_800F4E98().unk2 = 0;
        v.g.vs_battle_menuState().currentMenu = psx.conv(u8, menuState);
        v.g.D_800F4E98().unk0 = 1;

        if (arg1 == 0) c.vs_battle_playSfx10();

        if (v.g.vs_battle_menuItems().* == null) {
            v.g._loadedSubMenu().* = -1;

            _ = c.func_8007E180(6);

            const misc_addr: usize = @intFromPtr(c.vs_main_allocHeapR(0xB24));
            var var_a1: u16 = v.g.vs_main_settings().menuFlags;
            psx.put(v.g.vs_battle_stringBuf(), @as(?[*]u8, @ptrFromInt(misc_addr +% 0xA00)));
            psx.put(v.g.vs_battle_menuItems(), @as(?*v.vs_battle_menuItem_t, @ptrFromInt(misc_addr)));
            psx.put(v.g.vs_battle_rowTypeBuf(), @as(?[*]i32, @ptrFromInt(misc_addr +% 0xA60)));

            var i: c_int = 0;
            while (i < 3) : (i +%= 1) {
                var a0: c_int = v.g.D_800EBD68()[@intCast(i * 2)];
                while (a0 < v.g.D_800EBD68()[@intCast(i * 2 + 1)]) : (a0 +%= 1) {
                    const action = &v.g.actions()[@intCast(a0)];
                    if (psx.getBits(action, "unlocked") != 0) {
                        var_a1 = psx.conv(u16, @as(c_int, var_a1) | (@as(c_int, 1) << @as(u5, @intCast(i))));
                        break;
                    }
                }
            }

            if (v.g.vs_main_stateFlags().unkB5 != 0) {
                var_a1 |= 1;
            }
            if (v.g.vs_main_stateFlags().introState >= 3) {
                var_a1 |= 0x120;
            }
            v.g.vs_main_settings().menuFlags = var_a1;
            _ = c.func_800C930C(2);
        }
        return 1;
    }

    c.vs_battle_playInvalidSfx();
    return 0;
}
