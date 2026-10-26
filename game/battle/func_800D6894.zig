//! The battle queue step: runs the handler for a queued entry's kind when its
//! tag matches the current state, then retires the entry (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D6894 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Dispatches queue entry `arg1` by its kind when its tag matches `arg0`'s, then retires it through func_800D5780.
pub fn func_800D6894(arg0: ?*v.D_800F53B8_t, arg1: ?*v.func_800D5780_t) callconv(.c) c_int {
    // The entry pointer is a u32* in the PS1 layout: the offset is scaled by 4 (pointer minus int).
    const entry_base: u32 = psx.addr(psx.get(arg1.?.unk0).?);
    const neg: c_int = -%@as(c_int, arg1.?.unk6);
    const entry_addr: u32 = entry_base -% @as(u32, @bitCast(neg)) *% 4;
    const entry: *align(1) v.func_800D6894_t = @ptrFromInt(@as(usize, entry_addr));

    const expected = psx.get(arg0.?.unkD1C.unk30).?;
    if (@as(c_int, entry.unk0) & 0x1FF == @as(c_int, expected.unk2)) {
        const a1: u8 = entry.unk2;
        const a2: u8 = entry.unk3;

        switch (@as(c_int, entry.unk0) >> 9) {
            0 => c.func_800D6388(@ptrCast(arg0)),
            1 => c.func_800D63D0(@ptrCast(arg0)),
            2 => c.func_800D6418(@ptrCast(arg0)),
            3 => c.func_800D6448(@ptrCast(arg0), a1, a2),
            4 => c.func_800D64E4(),
            5 => c.func_800D6508(@ptrCast(arg0), a1),
            6 => c.func_800D6538(@ptrCast(arg0)),
            7 => c.func_800D6554(),
            8 => c.func_800D6574(@ptrCast(arg0)),
            9 => c.func_800D65A8(@ptrCast(arg0), a1),
            10 => c.func_800D65D8(@ptrCast(arg0), a1),
            11 => c.func_800D6628(@ptrCast(arg0), a1),
            12 => c.func_800D66CC(@ptrCast(arg0)),
            13 => c.func_800D66FC(@ptrCast(arg0), a1, a2),
            14 => c.func_800D67C4(@ptrCast(arg0), a1),
            15 => c.func_800D6860(@ptrCast(arg0)),
            else => {},
        }

        return c.func_800D5780(@ptrCast(arg1));
    }

    return 1;
}
