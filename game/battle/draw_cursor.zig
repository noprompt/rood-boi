//! Cursor animation step: sets the cursor sprite's texture page and advances the step
//! (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");
const sprite_item = @import("common").sprite_item;

const SiteFn = *const fn (c_int, ?*anyopaque, c_int, c_int, ?*anyopaque, ?*anyopaque) callconv(.c) void;

/// classic_hook.h PC_CLASSIC_SITE_MENU_CURSOR (a macro: not in `c`).
const site_menu_cursor: c_int = 26;

/// classic_hook.h pc_classic_menu_cursor: the hand's step, place, colour and `battle` (this caller).
const MenuCursor = extern struct { step: c_int, xy: c_int, color: c_int, battle: c_int };

/// The packet cursor.
fn scratchPtr() ?*anyopaque {
    return v.g.vs_scratch().unk0;
}

/// orig: vs_battle_drawCursor (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// Draws the cursor sprite for `position` with brightness `animStep`, then returns the next step (mod 16).
pub fn drawCursor(animStep: c_int, position: c_int) callconv(.c) c_int {
    const brightness: c_int = @as(c_int, psx.at(v.g.vs_battle_cursorBrightnessAnimation(), animStep).*);
    // (((position * 0x10) + 0xA) << 0x10) | 0xB4, in 32-bit wrapping arithmetic.
    const xy: c_uint = ((@as(c_uint, @bitCast(position)) *% 0x10 +% 0xA) << 16) | 0xB4;
    // PC_CLASSIC (classic_hook.h): the hand, as MAINMENU's, from its step and place; `battle` marks this caller.
    var record = MenuCursor{ .step = animStep, .xy = @bitCast(xy), .color = 0, .battle = 1 };
    const first = scratchPtr();
    // The scratchpad slot holds a guest primitive pointer, 4-aligned on every target.
    _ = sprite_item.sprite(null, brightness, @bitCast(xy), 0x100010, sprite_item.page, 0x37F83020);
    if (psx.weak(SiteFn, "pc_classic_site")) |site| site(site_menu_cursor, &record, 0, 0, first, scratchPtr());
    return (animStep +% 1) & 0xF;
}
