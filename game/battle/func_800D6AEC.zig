//! Runs the timed effect list of an effect block: each active entry's handler,
//! clearing the entries that finish, then counting the update
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D6AEC (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Runs each active entry of the effect's timeline, retires the ones that report done, then counts the update.
pub fn func_800D6AEC(arg0: ?*v.D_800F53B8_t, arg1: c_int) callconv(.c) void {
    const self = arg0.?;
    var var_s1: c_int = 0;
    while (var_s1 < @as(c_int, psx.get(self.unkD1C.unk30).?.unk0)) : (var_s1 +%= 1) {
        // x86 masks a variable shift count by 31; the count is 0..31 here.
        const sh: u5 = @intCast(var_s1 & 31);
        if (((psx.get(self.unkD1C.unk30).?.unk4 >> sh) & 1) != 0) {
            const temp_a1: *v.func_800D5780_t = @ptrCast(psx.at(psx.get(self.unkD1C.unk30).?, var_s1 *% 2 +% 1));
            // No case for types 0 and 11: temp is uninitialised in the original; 0 here.
            const temp: c_int = switch (@as(c_int, psx.getBits(&temp_a1.unk4, "unk0_0"))) {
                1 => c.func_800D57FC(@ptrCast(self), @ptrCast(temp_a1)),
                2 => c.func_800D5904(@ptrCast(self), @ptrCast(temp_a1)),
                3 => c.func_800D5A98(@ptrCast(self), @ptrCast(temp_a1), arg1),
                4 => c.func_800D5D74(@ptrCast(self), @ptrCast(temp_a1)),
                5 => c.func_800D5E00(@ptrCast(self), @ptrCast(temp_a1)),
                6 => c.func_800D5F8C(@ptrCast(self), @ptrCast(temp_a1)),
                7 => c.func_800D6048(@ptrCast(self), @ptrCast(temp_a1), @as(c_int, psx.get(self.unkD1C.unk30).?.unk1) & 2),
                8 => c.func_800D61AC(@ptrCast(self), @ptrCast(temp_a1)),
                9 => c.func_800D6298(@ptrCast(self), @ptrCast(temp_a1)),
                10 => c.func_800D6310(@ptrCast(self), @ptrCast(temp_a1)),
                12 => c.func_800D6894(@ptrCast(self), @ptrCast(temp_a1)),
                13 => c.func_800D6A18(@ptrCast(self), @ptrCast(temp_a1)),
                else => 0,
            };
            if (temp == 0) {
                const timeline = psx.get(self.unkD1C.unk30) orelse return;
                timeline.unk4 &= ~(@as(c_int, 1) << sh);
            }
        }
        if (psx.get(self.unkD1C.unk30) == null) return;
    }
    const timeline = psx.get(self.unkD1C.unk30).?;
    if ((timeline.unk1 & 1) == 0) {
        timeline.unk2 +%= 1;
    }
}
