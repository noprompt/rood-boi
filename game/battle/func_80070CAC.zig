//! Rebuilds the environment target list for the current action from room sections or spawn points (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80070CAC (src/BATTLE/BATTLE.PRG/146C.c)
/// Fills the environment target list of D_800F19CC for the current action.
pub fn func_80070CAC() callconv(.c) void {
    const base = v.g.D_800F19CC().*.?;
    const list: *align(1) v.environmentTargetList = @ptrCast(&base.unk8);
    var points: [4]v.func_8008D2C0_t = undefined;
    var count: c_int = undefined;
    var i: c_int = undefined;

    list.count = 0;
    switch (@as(c_int, list.action)) {
        93, 241 => {
            const rooms: [*]v._mpdRoomSection9 = @ptrCast(c.func_8008E400(&count));
            i = 0;
            while (i < count) : (i +%= 1) {
                const r = psx.at(rooms, i);
                if (r.unk6 != 16) {
                    const t = psx.at(&list.targets, list.count);
                    t.kind = 3;
                    t.x = psx.conv(i16, @as(c_int, r.unk0) *% 128 +% 64);
                    const yArg0: c_int = (@as(c_int, r.unk0) << 7) | 64;
                    const yArg1: c_int = (@as(c_int, r.unk2) << 7) | 64;
                    const yRaw: c_int = @as(c_int, c.func_8008DC7C(yArg0, yArg1));
                    t.y = psx.conv(i16, (yRaw << 17) >> 17);
                    t.z = psx.conv(i16, @as(c_int, r.unk2) *% 128 +% 64);
                    t.radius = 128;
                    list.count +%= 1;
                }
            }
        },
        79 => {
            count = c.func_8008D2C0(@ptrCast(&points));
            i = 0;
            while (i < count) : (i +%= 1) {
                const p = psx.at(&points, i);
                const t = psx.at(&list.targets, list.count);
                t.kind = 5;
                t.x = p.unk0;
                t.y = p.unk1;
                t.z = p.unk2;
                t.radius = 64;
                list.count +%= 1;
            }
        },
        else => {},
    }
    c.func_8007087C(@ptrCast(&base.unk8));
}
