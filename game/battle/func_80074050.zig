//! Battle room setup: camera, room section, enemy table and action index
//! (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80074050 (src/BATTLE/BATTLE.PRG/146C.c)
/// Sets up the battle room from a room section and resets the action index.
pub fn func_80074050(arg0: ?*v._mpdRoomSectionA, arg1: c_int) callconv(.c) void {
    // sp10[1] and sp10[3] are uninitialised in the original; zeroed here.
    var sp10: [4]c_short = .{ 0, 0, 0, 0 };

    v.g.D_800F196C().* = 9;
    v.g._cameraMode().* = 1;
    c.func_8006EF10();
    psx.put(&v.g.D_800F1910().unk0, arg0);
    _ = c.func_800A1108(arg1, @ptrCast(&v.g.D_800F1910().unk4));
    v.g.D_800F1910().unk4.unkC = arg1;

    var i: c_int = 0;
    while (i < 16) : (i +%= 1) {
        c.func_8009E5C4(i);
    }

    const section = arg0.?;
    sp10[0] = psx.conv(c_short, (@as(c_int, section.unk0.unk0) << 7) +% 0x40);
    sp10[2] = psx.conv(c_short, (@as(c_int, section.unk0.unk2) << 7) +% 0x40);
    c.func_8009E070(0, @ptrCast(&sp10), 1);

    v.g.D_800F19CC().*.?.unk4 = 0;
    v.g.D_800F19CC().*.?.unk8.actionIndex = 0;
}
