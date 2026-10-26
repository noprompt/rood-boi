//! Copies a zone's MPD LBA table into a fresh heap block (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _loadMpdLbas (src/BATTLE/BATTLE.PRG/146C.c)
/// Allocates the zone's MPD LBA table on the heap and copies `size` bytes from `arg0` into it.
pub fn loadMpdLbas(arg0: ?*anyopaque, size: c_int) callconv(.c) void {
    if (size == 0) {
        c.vs_main_nop9(0x8B, 0);
    }
    psx.put(&v.g._zoneContext().mpdLbas, c.vs_main_allocHeap(psx.conv(c_uint, size)));
    c.vs_main_memcpy(psx.get(v.g._zoneContext().mpdLbas), arg0, psx.conv(c_uint, size));
}
