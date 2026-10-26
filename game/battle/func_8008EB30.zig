//! Copies the 20-byte scene data block and writes its 33 packed command words into the GPU packet list at D_80068C1C (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008EB30 (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies the scene block into D_800F1D78 and writes its words into the packet list.
pub fn func_8008EB30(arg0: [*c]c_int) callconv(.c) void {
    _ = c.vs_main_memcpy(@ptrCast(v.g.D_800F1D78()), @ptrCast(arg0), @as(c_uint, @sizeOf([5]c_int)));

    const dst = v.g.D_80068C1C();
    var p: usize = 2;
    var a: usize = 0;

    dst[p] = (arg0[a] & 0xFFFFFF) | 0x30000000;
    a += 1;
    p += 1;

    for (0..8) |_| {
        p += 2;
        dst[p] = (arg0[a] & 0xFFFFFF) | 0x30000000;
        p += 1;
    }

    a += 1;

    for (0..16) |_| {
        p += 2;
        dst[p] = (arg0[a] & 0xFFFFFF) | 0x30000000;
        p += 1;
    }

    a += 1;

    for (0..8) |_| {
        p += 2;
        dst[p] = (arg0[a] & 0xFFFFFF) | 0x30000000;
        p += 1;
    }

    dst[p + 2] = (arg0[a + 1] & 0xFFFFFF) | 0x30000000;
}
