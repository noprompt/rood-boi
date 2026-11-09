//! The gradient gauge of a stat bar (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

const Lift = *const fn ([*]const c_uint, c_int, [*]c_uint, [*]u32) callconv(.c) ?[*]c_uint;

/// orig: vs_battle_renderStatBar (pc/src/game/BATTLE/BATTLE.PRG/5BF94.c)
/// A tile and a Gouraud quad `w` (0..64) wide at `xy`, blended from colour D_800EBC04[index] toward the bar's full colour, linked before `before`.
pub fn renderStatBar(color_index: c_int, w: c_int, before: [*c]c_uint, xy_arg: c_int) callconv(.c) void {
    const xy = xy_arg;
    const rgb1: c_uint = @bitCast(psx.at(v.g.D_800EBC04(), color_index).*);
    const prim: [*]u32 = @ptrCast(@alignCast(psx.get(v.g.vs_scratch().unk0).?));
    // Unsigned arithmetic: rgb1 is a u_int, so each term (and its >> 6) is.
    const uw: c_uint = @bitCast(w);
    const rest: c_uint = @bitCast(0x40 -% w);
    const rgb0: c_int = @bitCast((((uw *% 0xFF) +% ((rgb1 & 0xFF) *% rest)) >> 6) |
        ((((uw *% 0xF0) +% (((rgb1 >> 8) & 0xFF) *% rest)) >> 6) << 8) |
        ((((uw *% 0x9E) +% ((rgb1 >> 16) *% rest)) >> 6) << 16));
    // The bar as draw items: a tile (the draw mode the GPU is in), then a Gouraud quad in the dithered mode that leaves mode 0 set;
    // `w` 0 is the tile alone (draw_items.h pc_frame_lift_words places them where the packet linked).
    const lift = psx.weak(Lift, "pc_frame_lift_words").?;
    const xy0: c_uint = @bitCast(xy);
    const xy1: c_uint = xy0 +% ((1 << 16) | 1);
    const xy3: c_uint = xy1 +% ((3 << 16) | 0);
    const words = [13]c_uint{
        (96 << 24) | (0x40 << 16) | (0x28 << 8) | 0x00, xy0, 0x50042, // a tile, rgb 0x00, 0x28, 0x40
        (0xE1 << 24) | (1 << 9), // dithering on, 4-bit CLUT, half transparency, page 0
        @bitCast(rgb0 | (56 << 24)), xy1, rgb1, xy1 +% uw, @bitCast(rgb0), xy3, rgb1, xy3 +% uw, // a Gouraud quad
        0xE1 << 24, // mode 0
    };
    const next = lift(&words, if (w == 0) 3 else 13, @ptrCast(before), @ptrCast(prim)).?;
    psx.put(&v.g.vs_scratch().unk0, @as(*anyopaque, @ptrCast(next)));
}
