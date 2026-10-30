//! Copies a battle record into D_800F5230 and runs the battle-start setup
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CF0E8 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Stores a record, keeps its id and flag when the record's kind is 4, runs the setup calls and returns the status byte.
pub fn func_800CF0E8(record: ?*v.func_800CF0E8_t, id: c_int, flag: c_int) callconv(.c) c_int {
    v.g.D_800F5230().* = record.?.*;

    if (id != 0 and record.?.unk4 == 4) {
        v.g.D_800F522C().* = psx.conv(u8, id);
        v.g.D_800F54A9().* = psx.conv(u8, flag);
    }

    v.g.D_800F5318().* = psx.conv(u8, c.func_800CF49C());
    c.func_800D7890(1);
    c.func_800D1B18(psx.cptr(c.D_800F54D8_t, v.g.D_800F55A8()));
    c.func_800D1B18(psx.cptr(c.D_800F54D8_t, v.g.D_800F54D8()));
    c.func_800CF478(6);

    return @as(c_int, v.g.D_800F5318().*);
}
