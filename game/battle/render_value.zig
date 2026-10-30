//! Renders a value as BCD digits, one `_renderDigit` per nibble, moving left
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: vs_battle_renderValue (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Draws `value` as BCD digits right to left from `xy`, returning the x position after the last digit.
pub fn renderValue(font: c_int, xy: c_int, value: c_int, before: [*c]c_uint) callconv(.c) c_int {
    var x: c_int = xy;
    var val: c_int = value;
    var b: [*c]c_uint = before;

    // The field is a void pointer: `- 0x10` steps back 16 bytes.
    if (b == null) {
        b = @ptrFromInt(@intFromPtr(psx.get(v.g.vs_scratch().unk4).?) -% 16);
    }

    while (true) {
        val = c.vs_battle_toBCD(val);

        c._renderDigit(font, x, val & 0xF, b);

        const new_var: c_int = x -% 5;
        x = new_var -% font;
        val >>= 4;
        if (val == 0) break;
    }

    return x;
}
