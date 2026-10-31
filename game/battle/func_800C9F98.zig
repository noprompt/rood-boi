//! Sprite primitive setup in the scratch packet (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800C9F98 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Sets up a sprite primitive at the default texture page and writes its two command words.
pub fn func_800C9F98(arg0: c_int, arg1: c_int) callconv(.c) void {
    // The packet pointer is a word-aligned guest address: assert the alignment the C type needs.
    const packet: ?*align(4) anyopaque = @alignCast(psx.get(v.g.vs_scratch().unk8));
    const temp_v0: [*c]c.u_long = c.vs_battle_setSpriteDefaultTexPage(arg1, arg0, 0x60006, @ptrCast(packet));
    temp_v0[1] = 0xE1000017;
    temp_v0[4] = 0x373D80C0;
}
