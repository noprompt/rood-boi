//! Resets the battle menu and UI state and renders the menu images (src/BATTLE/BATTLE.PRG/5BF94.c).
const std = @import("std");
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CA9C0 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Clears the battle menu and UI state, then renders the menu images from `base`.
pub fn func_800CA9C0(base: ?*anyopaque) callconv(.c) void {
    v.g.D_800EB9AC().* = 0;
    v.g._loadedSubMenu().* = 0;
    v.g.D_800EB9AE().* = 0;
    v.g.D_800EB9B0().* = 0;
    v.g.D_800F4ED4().* = 0;
    v.g.D_800EB9B4().* = null;
    v.g.D_800EB9B8().* = null;
    v.g.D_800EB9BC().* = null;
    v.g.vs_battle_menuItems().* = null;
    v.g.D_800EB9CE().* = 0;
    v.g.vs_battle_lowerScreenUiState().* = 0;
    v.g.D_800EB9AF().* = 0;
    v.g.D_800EB9CC().* = 0;
    v.g.D_800EB9CD().* = 0;
    v.g.D_800EB9D0().s32 = 0xFFFFFF;
    v.g._menuBgUnpackedBuf().* = null;
    v.g.nameWindowText().* = null;
    _ = c.func_800CA97C();

    c.vs_battle_rMemzero(v.g.vs_battle_menuState(), 8);
    v.g.vs_battle_menuState().currentMenu = 0x3F;
    c.vs_battle_rMemzero(v.g.D_800F4E98(), @sizeOf(v.D_800F18EC_t));
    c.vs_battle_rMemzero(&v.g.textBoxes()[0], @sizeOf(v.vs_battle_textBox));
    c.vs_battle_rMemzero(v.g.vs_battle_submenuStates(), @sizeOf([16]u8));
    v.g.D_800F4EE8().* = std.mem.zeroes(v.D_800F4EE8_t);
    v.g.D_800F51B8().* = @as([*]u32, @ptrCast(v.g.D_800F4CD0()));

    c.vs_battle_renderImage(0x340, base, 0xE00040);
    c.vs_battle_renderImage(0x380, @as(?*anyopaque, @ptrFromInt(@intFromPtr(base) +% 0x7000)), 0xE00040);
    c.vs_battle_renderImage(0x4203C0, @as(?*anyopaque, @ptrFromInt(@intFromPtr(base) +% 0xE000)), 0x9E0040);
    _ = c.DrawSync(0);

    const ot: [*c]c.u_long = @ptrCast(v.g.D_800F51B8().*.?);
    _ = c.ClearOTag(ot, 0x22);
}
