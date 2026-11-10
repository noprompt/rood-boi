//! Draws one shaded textured quad (an FT4 primitive) at the scratchpad's
//! packet cursor and links it into the ordering table (pc/src/game/BATTLE/BATTLE.PRG/2842C.c).
const common = @import("common");
const psx = common.psx;
const sprite_item = common.sprite_item;

/// A corner (x low, y high) and a texel (u low, v high) as the packets packed them.
fn xy(x: c_int, y: c_int) c_int {
    return (x & 0xFFFF) | (y << 16);
}
fn uv(u: c_int, w: c_int) c_int {
    return (u & 0xFF) | ((w & 0xFF) << 8);
}

/// orig: func_800957D0 (pc/src/game/BATTLE/BATTLE.PRG/2842C.c)
/// Builds a 16x10 textured quad centred on (arg0 + 8, arg1), takes its texture column from arg2, and adds it to the ordering table.
pub fn func_800957D0(arg0: c_int, arg1: c_int, arg2: c_int) callconv(.c) void {
    const x: c_int = arg0 -% 8;
    // arg2 <<= 4 wraps as a 32-bit shift.
    const tex: c_int = @bitCast(@as(c_uint, @bitCast(arg2)) << 4);
    // The slot 20 bytes before the table the scratchpad names (its word at +4).
    const ot: ?*anyopaque = @ptrFromInt(@as(usize, @as(*const u32, @ptrFromInt(0x1F800004)).*) -% 20);

    // A raw-textured quad (the shade bit set on it: setShadeTex(prim, 1)).
    sprite_item.ft4(ot, true, false, 0x17, 0x373E, 0,
        &[4]c_int{ xy(x, arg1 -% 5), xy(x +% 16, arg1 -% 5), xy(x, arg1 +% 5), xy(x +% 16, arg1 +% 5) },
        &[4]c_int{ uv(tex +% 0x40, 0x30), uv(tex +% 0x50, 0x30), uv(tex +% 0x40, 0x3A), uv(tex +% 0x50, 0x3A) });
}
