//! Actor turn and walk requests (D2: 4A0A8.c's inline assembly; oracle pc/src/battle_motion.c).
const psx = @import("common").psx;
const c = @import("c_battle_motion");
const v = @import("views_battle_motion");

/// orig: func_800B6580 (pc/src/battle_motion.c)
/// Starts a turn toward position[0] at rate `b` unless one is pending (the low
/// nibble of byte 0xB): clears the halfword at 0x1A, stores the target word at
/// 0x5EC and `b << 16` at 0x5F0, and sets byte 0xB to 1. The linked actor
/// (byte 0x17FD) gets the same request when its id is 2 or more.
pub fn requestTurn(id: c_int, position: [*]const c_int, b: c_int) callconv(.c) void {
    const a = v.g.D_800F4538()[@intCast(id)].?;
    const flags = psx.fieldAt(u8, &a.unk0._bits_skip, 3);
    if (flags.* & 0xf != 0) return;
    const linked: c_int = a.unk17FD;
    a.unk0.unk1A = 0;
    psx.fieldAt(c_int, &a.unk5EC, 0).* = position[0];
    psx.fieldAt(c_uint, &a.unk5EC, 4).* = @as(c_uint, @bitCast(b)) << 16;
    flags.* = 1;
    if (linked >= 2) c.func_800B6580(linked, @constCast(position), b);
}

/// orig: func_800B668C (pc/src/battle_motion.c)
/// func_800AA8D0, then func_800A249C, both with the same id and `a`.
pub fn advanceMotion(id: c_int, a: i16, b: c_int) callconv(.c) void {
    c.func_800AA8D0(id, a, b);
    c.func_800A249C(id, a);
}
