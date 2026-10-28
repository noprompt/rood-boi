//! Runs the room door section update and reports its three door fields (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007C654 (src/BATTLE/BATTLE.PRG/146C.c)
/// Updates a room door section, then passes three bitfields of its result to func_8008B960.
pub fn func_8007C654(section: ?*v._mpdRoomDoorSection_t, arg1: c_int, arg2: c_int) callconv(.c) void {
    var sp10: v.func_8006EBF8_t = undefined;

    _ = c.func_8007C5C0(@ptrCast(section), arg1, arg2);
    _ = c.func_800A1108(0, &sp10);
    c.func_8008B960(
        @as(c_int, psx.getBits(&sp10.unk0.unk0.fields, "unk0_0")),
        @as(c_int, psx.getBits(&sp10.unk0.unk0.fields, "unk0_16")),
        @as(c_int, psx.getBits(&sp10.unk0.unk0.fields, "unk0_8")),
    );
}
