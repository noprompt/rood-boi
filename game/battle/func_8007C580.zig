//! Room door section: runs the door setup, then passes three packed result bytes on to func_8008B960 (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007C580 (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the room door setup for a section, then passes three packed result bytes to func_8008B960.
pub fn func_8007C580(arg0: ?*v._mpdRoomDoorSection_t, arg1: c_int, arg2: c_int) callconv(.c) void {
    var sp10: v.func_8006EBF8_t = undefined;
    _ = c.func_8007C4E0(@ptrCast(arg0), arg1, arg2);
    _ = c.func_800A1108(0, &sp10);
    const fields = &sp10.unk0.unk0.fields;
    c.func_8008B960(
        @as(c_int, psx.getBits(fields, "unk0_0")),
        @as(c_int, psx.getBits(fields, "unk0_16")),
        @as(c_int, psx.getBits(fields, "unk0_8")),
    );
}
