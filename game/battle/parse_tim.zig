//! TIM image header parsing for battle textures (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// A guest word at `addr`, read as the C reads a `u_long`.
fn word(addr: usize) *align(1) u32 {
    return @ptrFromInt(addr);
}

/// orig: vs_battle_parseTim (src/BATTLE/BATTLE.PRG/146C.c)
/// Fills a TIM_IMAGE's mode, optional CLUT rect and address, and pixel rect and address from a TIM blob.
pub fn parseTim(data: [*c]c_uint, tim: ?*v.TIM_IMAGE) callconv(.c) void {
    const t = tim.?;
    // Pointer arithmetic on u_long*: byte offsets, wrapping like the C's address arithmetic.
    var cursor: usize = @intFromPtr(data) +% 4; // ++arg0
    t.mode = word(cursor).*; // tim->mode = *arg0
    cursor +%= 4; // ++arg0

    if ((t.mode & 8) != 0) {
        psx.put(&t.crect, @as(?*v.RECT, @ptrFromInt(cursor +% 4))); // (RECT*)(arg0 + 1)
        psx.put(&t.caddr, @as(?*u32, @ptrFromInt(cursor +% 12))); // (u_long*)arg0 + 3
        const count: u32 = word(cursor).* >> 2;
        cursor +%= @as(usize, count) *% 4; // arg0 += *arg0 >> 2
    } else {
        psx.put(&t.crect, null);
        psx.put(&t.caddr, null);
    }

    psx.put(&t.prect, @as(?*v.RECT, @ptrFromInt(cursor +% 4))); // (RECT*)(arg0 + 1)
    psx.put(&t.paddr, @as(?*u32, @ptrFromInt(cursor +% 12))); // arg0 + 3
}
