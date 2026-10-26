//! The battle menu item renderer: its label, its gradient background quad and its sub text
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: vs_battle_renderMenuItem (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Draws a menu item's label, gradient background and sub text into the packet at the scratchpad cursor.
pub fn renderMenuItem(menuItem: ?*v.vs_battle_menuItem_t) callconv(.c) void {
    const m = menuItem.?;
    var y: c_int = m.gradientState;
    const scratchSlot: *const u32 = @ptrFromInt(0x1F800008);
    const scratchAddr: u32 = scratchSlot.* +% 8;
    const scratch: [*c]c_uint = @ptrFromInt(@as(usize, scratchAddr));
    const w: c_int = m.w;
    const bgWidth: c_int = m.backgroundWidth;
    const text: [*]u8 = &m.text;

    if (m.state != 0) {
        if ((m.selected | m.invertGradient) != 0 and m.unselectable == 0) {
            y = 8;
        }

        var color: c_int = m.fontColor;
        if (color == 0) {
            color = @as(c_int, m.unselectable) * 3;
        }

        c.vs_battle_setFontStyle(color +% 4);

        const tempX: c_int = m.x;
        var penX: c_int = tempX +% 6;
        if (psx.conv(c_uint, @as(c_int, m.rowIcon) -% 1) < 23) {
            penX = tempX +% 22;
        }

        var ch: c_int = text[0];
        var pText: [*]u8 = text + 1;
        while (ch != 0xFF) {
            if (ch == c.vs_char_spacing) {
                penX +%= @as(c_int, pText[0]);
                pText += 1;
            } else {
                penX = c.vs_battle_printVariableWidthFontChar(psx.conv(c_uint, ch), penX, m.y, scratch - 3);
            }
            ch = @as(c_int, pText[0]);
            pText += 1;
        }

        const topColor: c_int = c.vs_battle_uiGradientStop(psx.conv(c_uint, 8 -% y), psx.conv(c_uint, bgWidth), 128);
        const bottomColor: c_int = c.vs_battle_uiGradientStop(psx.conv(c_uint, y), psx.conv(c_uint, bgWidth), 128);

        if ((bgWidth & 7) != 0) {
            m.backgroundWidth = psx.conv(u8, (bgWidth +% 1) & 0xF);
        }

        if (y != 0) {
            m.gradientState = psx.conv(u8, y -% 1);
        }

        // The C reads x and y as one int: x is the low half (zero-extended), y the high half (sign-extended).
        const x: c_int = @as(u16, @bitCast(m.x));
        y = m.y;

        c.vs_battle_addTile(
            scratch + 1,
            0x60000000,
            @bitCast((bits(x +% 2) & 0xFFFF) | (bits(y +% 2) << 16)),
            w | 0xC0000,
        );

        const primAddr: u32 = @as(*const u32, @ptrFromInt(0x1F800000)).*;
        const prim: [*c]c_uint = @ptrFromInt(@as(usize, primAddr));

        prim[0] = (scratch[0] & 0xFFFFFF) | 0x0A000000;
        prim[1] = tpage(c.ditheringOn);
        prim[2] = bits((c.primPolyG4 << 24) | topColor);
        prim[3] = bits(x) | (bits(y) << 16);
        prim[4] = bits(bottomColor);
        prim[5] = bits((x +% w) & 0xFFFF) | (bits(y) << 16);
        prim[6] = bits(topColor);
        prim[7] = bits(x) | (bits(y +% 12) << 16);
        prim[8] = bits(bottomColor);
        prim[9] = bits((x +% w) & 0xFFFF) | (bits(y +% 12) << 16);
        prim[10] = tpage(c.ditheringOff);

        scratch[0] = (primAddr << 8) >> 8;
        @as(*u32, @ptrFromInt(0x1F800000)).* = primAddr +% 44;

        if (psx.get(m.subText)) |subText| {
            c.vs_battle_renderTextRaw(
                subText,
                @bitCast(bits(x -% 10) | (bits(y +% 1) << 16)),
                @ptrCast(scratch),
            );
        }
    }
}

/// The bit pattern of a C int.
fn bits(value: c_int) c_uint {
    return @bitCast(value);
}

/// getTpage(0, 0, clut4Bit, semiTransparencyHalf, dithering): the macro's x and y terms are zero.
fn tpage(dithering: c_int) c_uint {
    return (0xE1 << 24) |
        (@as(c_uint, @intCast(dithering & 1)) << 9) |
        ((@as(c_uint, @intCast(c.clut4Bit)) & 3) << 7) |
        ((@as(c_uint, @intCast(c.semiTransparencyHalf)) & 3) << 5);
}
