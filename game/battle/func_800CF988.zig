//! Sets the frame page on record 1 and draws the four records of a quad at their
//! left edge (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CF988 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Finds the leftmost of four records, sets record 1's page from the frame buffer and passes each record to func_800CF92C.
pub fn func_800CF988(arg0: ?*v.func_800CF988_t, arg1: c_int, arg2: c_int, arg3: c_int) callconv(.c) void {
    const a = arg0.?;
    var left: c_int = 320;

    if (@as(c_int, a.unk8[0].unk4) < left) {
        left = a.unk8[0].unk4;
    }

    if (@as(c_int, a.unk8[1].unk4) < left) {
        left = a.unk8[1].unk4;
    }

    if (@as(c_int, a.unk8[2].unk4) < left) {
        left = a.unk8[2].unk4;
    }

    if (@as(c_int, a.unk8[3].unk4) < left) {
        left = a.unk8[3].unk4;
    }

    left &= ~@as(c_int, 0x3F);
    const page: c_int = @divTrunc(left, 64);
    const frame_page: c_int = if ((v.g.vs_main_frameBuf().* & 1) != 0) page else page +% 5;
    a.unk8[1].unkA = psx.conv(i16, frame_page | arg3 | 0x100);
    const offset: c_int = arg1 -% left;

    c.func_800CF92C(offset, arg2, @as(*align(1) c_int, @ptrCast(&a.unk8[0].unk4)).*, &a.unk8[0].unk8);
    c.func_800CF92C(offset, arg2, @as(*align(1) c_int, @ptrCast(&a.unk8[1].unk4)).*, &a.unk8[1].unk8);
    c.func_800CF92C(offset, arg2, @as(*align(1) c_int, @ptrCast(&a.unk8[2].unk4)).*, &a.unk8[2].unk8);
    c.func_800CF92C(offset, arg2, @as(*align(1) c_int, @ptrCast(&a.unk8[3].unk4)).*, &a.unk8[3].unk8);
}
