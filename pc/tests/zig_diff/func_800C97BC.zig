//! zig_diff spec: func_800C97BC -> func_800C97BC.func_800C97BC (5BF94.c).
//! Inputs: the current menu over edges around 0x1F, 0x3F, 0x7F and the 0x40
//! page bits; the shortcut byte (5 or not); loadMenuPrg's result (zero, or
//! nonzero of either sign); func_800C930C's result (zero, negative, positive);
//! and an arena array of ten menu items. pc_ui_menu_hide_rows is stubbed to
//! return 0 or 1 by a draw, so the item loop runs on about half the paths that
//! reach it and the skip side is taken too. `miscIndex > 0` only runs when
//! `miscIndex != 0`, so its two sides can never be equal: that flag is waived.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800C97BC));

pub const classes = [_][:0]const u8{
    "menu-7f",
    "menu-done",
    "loaded-shortcut",
    "loaded-exec",
    "idle-misc-positive",
    "idle-misc-negative",
    "idle-misc-zero",
    "page-high",
    "page-low",
};

const menu_edges = [_]u8{ 0x7F, 0x3F, 0x1F, 0x1E, 0x20, 0x40, 0x41, 0x5F, 0x7E, 0x80, 0xBF, 0xFF, 0x00, 0x01, 0x3E };

// Results the stubs return this iteration (set by prepare, same in both runs).
var load_ret: c_int = 0;
var misc_ret: c_int = 0;

pub const stubs = struct {
    pub fn vs_battle_loadMenuPrg(ctx: *zd.Ctx, arg0: anytype) c_int {
        _ = arg0;
        // The loader may change the shortcut byte the C reads back.
        if (ctx.value(u1) == 1) v.g.vs_battle_shortcutInvoked().* = ctx.value(u8);
        return load_ret;
    }

    pub fn func_800C930C(ctx: *zd.Ctx, arg: anytype) c_int {
        _ = arg;
        // A menu function may move the current menu the C stores into.
        if (ctx.value(u1) == 1) v.g.vs_battle_menuState().currentMenu = ctx.value(u8);
        return misc_ret;
    }

    pub fn pc_ui_menu_hide_rows(ctx: *zd.Ctx) c_int {
        // Half the calls hide nothing, so the item loop runs; the rest skip it.
        return if (ctx.value(u1) == 1) 1 else 0;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const items = ctx.alloc([10]v.vs_battle_menuItem_t);
    v.g.vs_battle_menuItems().* = &items[0];
    v.g.vs_battle_menuState().currentMenu = ctx.pick(u8, &menu_edges);
    v.g.vs_battle_shortcutInvoked().* = ctx.pick(u8, &.{ 5, 4, 0, 6, 0x85 });
    load_ret = if (ctx.chance(2)) 0 else ctx.pick(c_int, &.{ 1, -1, 0x100, std.math.minInt(c_int) });
    misc_ret = ctx.pick(c_int, &.{ 0, 0, -1, 1, 0x40, -0x7FFF, 0x7FFF });
    return .{};
}

pub fn classify(_: Args) usize {
    const cur: u8 = v.g.vs_battle_menuState().currentMenu;
    if (cur == 0x7F) return 0;
    if ((cur & 0x3F) == 0x3F) return 1;
    if (load_ret != 0) return if (v.g.vs_battle_shortcutInvoked().* == 5) 2 else 3;
    if ((cur & 0x3F) == 0) {
        if (misc_ret == 0) return 6;
        return if (misc_ret > 0) 4 else 5;
    }
    return if (cur >= 0x1F) 7 else 8;
}
