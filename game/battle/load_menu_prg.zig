//! Loads the battle menu sub-program overlay from CD and unpacks the menu background
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: vs_battle_loadMenuPrg (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Starts loading menu sub-program `request & 0x1F` and, once it is in, finishes the load and sets up the menu background.
pub fn loadMenuPrg(request: c_int) callconv(.c) c_int {
    const state = v.g.vs_battle_menuState();
    const subMenu: c_int = request & 0x1F;

    if (subMenu == 31) {
        return 1;
    }

    if (subMenu == 0 and @as(c_int, v.g._loadedSubMenu().*) > 0) {
        return 1;
    }

    if (@as(c_int, v.g._loadedSubMenu().*) != subMenu) {
        var fileData: c_uint = undefined;

        v.g._loadedSubMenu().* = psx.conv(i8, subMenu);
        state.loading = 1;

        if (v.g.vs_battle_shortcutInvoked().* != 5) {
            // subMenu is 0..30 here (31 returned above), so the index is in range.
            fileData = psx.conv(c_uint, v.g._menuLbas()[@intCast(subMenu)]);
        } else {
            fileData = (85000 << 8) | (36864 >> 11);
        }

        var file: v.vs_main_CdFile = .{
            .lba = psx.conv(i32, fileData >> 8),
            .size = psx.conv(i32, (fileData & 0xFF) << 11),
        };
        // The C macro evaluates the allocation once (the sizeof operand is not evaluated).
        psx.put(&state.cdQueue, @as(?*v.vs_main_CdQueueSlot, @ptrCast(
            c.vs_main_allocateCdQueueSlot(psx.cptr(c.vs_main_CdFile, &file)),
        )));

        const overlaySlot: ?*anyopaque = if (subMenu == 0)
            v.g.vs_overlay_slots()[1]
        else
            v.g.vs_overlay_slots()[2];

        c.vs_main_cdEnqueue(@ptrCast(psx.get(state.cdQueue)), overlaySlot);
    }

    if (state.loading == 0) {
        if (v.g._menuBgUnpackedBuf().* != null) {
            c.vs_main_freeHeapR(@ptrCast(v.g._menuBgUnpackedBuf().*.?));

            v.g._menuBgUnpackedBuf().* = null;

            c.vs_mainMenu_initInventory();
        }

        return 1;
    }

    // The C dereferences the queue slot unconditionally.
    const slot = psx.get(state.cdQueue).?;
    if (@as(c_int, slot.state) == c.vs_main_CdQueueStateLoaded) {
        c.vs_main_freeCdQueueSlot(@ptrCast(slot));
        c.vs_main_wait();

        state.loading = 0;

        if (v.g.D_800F4FDB().* != 0) {
            if (v.g.vs_battle_shortcutInvoked().* == 5) {
                c.vs_mainMenu_miscItemsShortcutMenu(1);
                return 0;
            }
            return 1;
        }

        if (subMenu == 0) {
            // The heap returns 16-byte aligned blocks, so the u32 view is aligned.
            const buf: ?[*]u32 = @ptrCast(@alignCast(c.vs_main_allocHeapR(0xB400)));
            v.g._menuBgUnpackedBuf().* = buf;
            c.vs_mainMenu_unpackMenubg(@ptrCast(buf));
        }
    }

    return 0;
}
