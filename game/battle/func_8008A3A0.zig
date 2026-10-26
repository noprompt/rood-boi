//! Battle teardown: clears the two frame buffers' order tables and transitions,
//! then frees the zone's enemy list and the battle's heap blocks (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008A3A0 (src/BATTLE/BATTLE.PRG/146C.c)
/// Clears and transitions both frame buffers, then tears down the battle's heap and scene state.
pub fn func_8008A3A0() callconv(.c) void {
    var i: c_int = 0;
    while (i < 2) : (i += 1) {
        const frame: ?*anyopaque = psx.at(v.g.D_80055C80(), v.g.vs_main_frameBuf().*).*;
        const frame_addr: u32 = if (frame) |p| psx.addr(p) else 0;
        psx.put(&v.g.vs_scratch().unk4, @as(?*anyopaque, @ptrFromInt(@as(usize, frame_addr +% 0x10))));

        // The scratch slot holds a guest address; it is passed on as the C's pointer value.
        const slot = psx.get(v.g.vs_scratch().unk4);
        const slot_addr: u32 = if (slot) |p| psx.addr(p) else 0;
        _ = c.ClearOTagR(@ptrFromInt(@as(usize, slot_addr)), 0x800);
        _ = c.func_8007DF40();
        c._drawScreenTransition(@ptrFromInt(@as(usize, slot_addr)));

        _ = c.func_8007629C(@ptrFromInt(@as(usize, slot_addr +% 0x1FFC)));
    }

    _ = c.DrawSync(0);
    _ = c.vs_main_gametimeUpdate(0);
    c.func_800BEB34();
    c._setRoomSeen();
    _ = c.func_8008ABF0(0);

    if (psx.get(v.g._zoneContext().mpdEnemies)) |mpd| {
        c.vs_main_freeHeap(mpd);
    }

    if (v.g.D_800F192C().*) |actor| {
        c.func_800E7454(@ptrCast(actor));
    }
    c.func_8008A364();
    c.func_800E6F1C();
    c.func_80095B7C(0, 0);
    c.func_8009D6F4();
    c.func_8008A6FC();
    c.vs_main_freeHeap(v.g.D_8005E0C0()[1]);
    c.vs_main_freeHeap(v.g.D_8005E0C0()[0]);
}
