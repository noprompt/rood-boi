//! zig_diff spec: func_800CACD0 -> func_800CACD0.func_800CACD0 (5BF94.c).
//! Inputs: menuState and arg1 over edge values (0, -1, 255, 256, the sign
//! boundary), the current menu at 0x3F or another value, the menu items
//! already set or null (the allocation path), the three action ranges from
//! D_800EBD68 empty, equal or wide, every action locked, unlocked or mixed,
//! unkB5 with and without the sign bit, introState at, below and above 3.
//! The callees write the fields the C reads back (introState, unkB5,
//! menuFlags, the menu items pointer) and may return null from the allocator.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CACD0));

pub const classes = [_][:0]const u8{ "invalid-menu", "already-open", "init-intro-3-up", "init-intro-low" };

pub const stubs = struct {
    pub fn vs_main_allocHeapR(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        _ = size;
        if (ctx.value(u8) < 32) return null;
        return @ptrCast(ctx.allocBytes(0xB24, 16));
    }

    pub fn func_8007E180(ctx: *zd.Ctx, arg0: anytype) c_int {
        _ = arg0;
        if (ctx.value(u1) == 1) v.g.vs_main_stateFlags().unkB5 = ctx.value(u8);
        if (ctx.value(u1) == 1) v.g.vs_main_stateFlags().introState = ctx.value(u8);
        if (ctx.value(u1) == 1) v.g.vs_main_settings().menuFlags = ctx.value(u16);
        return ctx.value(c_int);
    }

    pub fn func_800C930C(ctx: *zd.Ctx, arg: anytype) c_int {
        _ = arg;
        if (ctx.value(u1) == 1) v.g.vs_battle_shortcutInvoked().* = ctx.value(u8);
        return ctx.value(c_int);
    }

    pub fn func_800CABE0(ctx: *zd.Ctx, arg: anytype) c_int {
        _ = arg;
        const r = ctx.value(u8);
        if (r < 64) v.g.vs_battle_menuItems().* = null;
        if (r >= 192) v.g.vs_battle_menuItems().* = ctx.alloc(v.vs_battle_menuItem_t);
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const menuState = ctx.pick(c_int, &.{ 0, 1, 255, 256, -1, 0x3F, 0x40 });
    const arg1 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000 });

    const menu = v.g.vs_battle_menuState();
    menu.currentMenu = if (ctx.chance(4)) ctx.edge(u8, &.{ 0, 0x3E, 0x40, 0xFF }) else 0x3F;

    var items: ?*v.vs_battle_menuItem_t = null;
    if (ctx.chance(3)) items = ctx.alloc(v.vs_battle_menuItem_t);
    v.g.vs_battle_menuItems().* = items;

    const flags = v.g.vs_main_stateFlags();
    flags.unkB5 = ctx.pick(u8, &.{ 0, 1, 0x80, 0xFF });
    flags.introState = ctx.pick(u8, &.{ 0, 2, 3, 4, 255 });
    v.g.vs_main_settings().menuFlags = ctx.int(u16);

    const acts = v.g.actions();
    const mode = ctx.range(u8, 0, 2);
    for (acts) |*a| {
        const bit: u1 = switch (mode) {
            0 => 0,
            1 => 1,
            else => ctx.int(u1),
        };
        psx.setBits(a, "unlocked", bit);
    }

    const tbl = v.g.D_800EBD68();
    var i: usize = 0;
    while (i < 3) : (i += 1) {
        const lo = ctx.pick(u8, &.{ 0, 1, 8, 255 });
        const hi: u8 = if (ctx.chance(4)) lo else if (ctx.chance(2)) ctx.range(u8, 0, lo) else ctx.range(u8, lo, 255);
        tbl[i * 2] = lo;
        tbl[i * 2 + 1] = hi;
    }

    return .{ menuState, arg1 };
}

pub fn classify(args: Args) usize {
    _ = args;
    if (v.g.vs_battle_menuState().currentMenu != 0x3F) return 0;
    if (v.g.vs_battle_menuItems().* != null) return 1;
    return if (v.g.vs_main_stateFlags().introState >= 3) 2 else 3;
}
