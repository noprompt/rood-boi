//! Draws the two frame sprites of a gim image (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CC128 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Draws the image's two frame sprites, offset by the frame buffer's x position.
pub fn func_800CC128(gim: ?*v.gim_t, arg1: c_int, prims: [*c]c_uint) callconv(.c) void {
    const temp_s0: c_int = @as(c_int, gim.?.unk3);

    if (temp_s0 == 0x80) {
        c.func_800CBBCC(@ptrCast(gim), arg1, prims);
        return;
    }

    v.g.D_800F51C8().* = 1;

    c.func_800CBBCC(@ptrCast(gim), arg1, prims);

    var var_s1: c_int = 0;
    if (v.g.vs_main_frameBuf().* == 0) {
        var_s1 = 0x140;
    }

    const new_var: c_uint = psx.conv(c_uint, @as(c_int, 0x120));

    const sprite0 = c.vs_battle_setSprite(0x80 -% temp_s0, 0, 0xF00100, prims);
    sprite0[1] = (psx.conv(c_uint, var_s1) >> 6) | new_var | 0xE1000000;

    const sprite1 = c.vs_battle_setSprite(0x80 -% temp_s0, 0x100, 0xF00040, prims);
    sprite1[1] = psx.conv(c_uint, (var_s1 +% 0x100) >> 6) | new_var | 0xE1000000;
}
