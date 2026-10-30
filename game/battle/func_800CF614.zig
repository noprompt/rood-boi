//! Unlinks a node from the D_800F54B0 list and frees it (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CF614 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Unlinks `entry` from the list at D_800F54B0, frees what it owns and the node.
pub fn func_800CF614(entry: ?*v.D_800F53B8_t) callconv(.c) void {
    var cur: ?*v.D_800F53B8_t = v.g.D_800F54B0().*;
    if (cur == entry) {
        v.g.D_800F54B0().* = psx.get(entry.?.next);
    } else {
        while (psx.get(cur.?.next) != null) {
            if (psx.get(cur.?.next) == entry) {
                // psx_copy: the raw guest address of entry's successor.
                cur.?.next = entry.?.next;
                break;
            }
            cur = psx.get(cur.?.next);
        }
    }
    c.func_800D2904(@ptrCast(entry));
    c.func_800CF514(@as(c_int, psx.getBits(entry.?, "unk14_0")));
    c.vs_main_freeHeapR(entry);
}
