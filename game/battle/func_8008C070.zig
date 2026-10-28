//! Records a room section in the first free slot of the battle's section table (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: func_8008C070 (src/BATTLE/BATTLE.PRG/146C.c)
/// Counts one more call, then stores `arg0` and the room section in the first free of the 8 slots.
pub fn func_8008C070(arg0: c_int, arg1: ?*v._mpdRoomSectionA) callconv(.c) void {
    const counter = v.g.D_800F1D6A();
    counter.* +%= 1;

    const slots = v.g.D_800F1D28();
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        if (slots[i].unk0 == 0) {
            slots[i].unk0 = arg0;
            psx.put(&slots[i].unk4, arg1);
            return;
        }
    }
}
