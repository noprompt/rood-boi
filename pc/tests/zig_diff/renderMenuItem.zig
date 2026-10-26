//! zig_diff spec: vs_battle_renderMenuItem -> render_menu_item.renderMenuItem (5BF94.c).
//! Inputs: a menu item in the arena with its state (hidden or shown), the
//! selected/invertGradient/unselectable flags (the gradient override and the
//! font-colour fallback), any fontColor, rowIcon around 0-25 (0 is the
//! unsigned-compare trap), any x/y (i16 edges included), a width and gradient
//! state, and a text of 0-26 glyphs and spacing pairs ended by 0xFF. Its
//! subText is null or an arena address. The scratchpad holds an arena scratch
//! block (scratch = block + 16) and an arena primitive buffer. The printf stub
//! writes scratch[0] and addTile writes it back through `before[-1]`, so the C
//! reads both callee writes.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").renderMenuItem));

pub const classes = [_][:0]const u8{ "hidden", "selected", "no-subtext", "subtext" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const item = ctx.alloc(v.vs_battle_menuItem_t);

    // The scratchpad words the C reads: the scratch word (scratch = word + 8,
    // so scratch = block + 16) and the primitive buffer pointer.
    const sb = ctx.allocBytes(64, 16);
    const pb = ctx.allocBytes(64, 16);
    @as(*align(1) u32, @ptrFromInt(zd.scratchpad + 0x08)).* = psx.addr(sb) + 8;
    @as(*align(1) u32, @ptrFromInt(zd.scratchpad)).* = psx.addr(pb);

    item.state = if (ctx.chance(6)) 0 else ctx.pick(u8, &.{ 1, 2, 0x80, 0xFF });
    item.w = ctx.pick(u8, &.{ 0, 1, 0x7F, 0x80, 0xFF });
    item.backgroundWidth = ctx.pick(u8, &.{ 0, 1, 6, 7, 8, 0x80, 0xFF });
    item.gradientState = ctx.pick(u8, &.{ 0, 1, 7, 8, 255 });
    item.selected = if (ctx.chance(3)) ctx.pick(u8, &.{ 1, 0x80 }) else 0;
    item.invertGradient = if (ctx.chance(4)) ctx.pick(u8, &.{ 1, 0x80 }) else 0;
    item.unselectable = if (ctx.chance(3)) ctx.pick(u8, &.{ 1, 2, 0x80, 0xFF }) else 0;
    item.fontColor = ctx.pick(u8, &.{ 0, 0, 1, 3, 0x7F, 0xFF });
    item.rowIcon = ctx.pick(u8, &.{ 0, 1, 22, 23, 24, 25, 255 });
    item.x = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 100 });
    item.y = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 100 });

    // Text: spacing pairs (250 then a width byte) and glyphs, ended by 0xFF
    // within the 32 bytes. The C's `c` is unsigned here, so 0xFF terminates.
    var i: usize = 0;
    const tokens = ctx.range(u8, 0, 10);
    var t: u8 = 0;
    while (t < tokens and i < 26) : (t += 1) {
        if (ctx.chance(4)) {
            item.text[i] = 250;
            item.text[i + 1] = ctx.range(u8, 0, 254);
            i += 2;
        } else {
            item.text[i] = ctx.range(u8, 0, 249);
            i += 1;
        }
    }
    item.text[i] = 0xFF;

    // subText: a raw guest address, null sometimes.
    const raw: *align(1) u32 = @ptrCast(&item.subText);
    raw.* = if (ctx.chance(3)) 0 else psx.addr(ctx.allocBytes(8, 4));

    return .{item};
}

pub fn classify(args: Args) usize {
    const item = args[0].?;
    if (item.state == 0) return 0;
    if ((item.selected | item.invertGradient) != 0 and item.unselectable == 0) return 1;
    // The guest address stored in subText itself (not the address of the field).
    const raw: *align(1) const u32 = @ptrCast(&item.subText);
    return if (raw.* == 0) 2 else 3;
}

pub const stubs = struct {
    pub fn vs_battle_printVariableWidthFontChar(ctx: *zd.Ctx, glyphId: anytype, x: anytype, y: anytype, ot: anytype) c_int {
        _ = glyphId;
        _ = x;
        _ = y;
        if (ctx.value(u8) < 64) {
            // ot = scratch - 3, so ot[3] is the scratch word the C reads back.
            const p: [*]u32 = @ptrCast(ot);
            p[3] = ctx.value(u32);
        }
        return ctx.value(c_int);
    }

    pub fn vs_battle_addTile(ctx: *zd.Ctx, before: anytype, rgb0: anytype, xy: anytype, wh: anytype) void {
        _ = rgb0;
        _ = xy;
        _ = wh;
        if (ctx.value(u8) < 128) {
            // before = scratch + 1, so before[-1] is the scratch word.
            const p: [*]u32 = @ptrCast(before);
            (p - 1)[0] = ctx.value(u32);
        }
    }
};
