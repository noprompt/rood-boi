//! Frees each entry of the battle's linked list and its attached block (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CF1A8 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Walks the battle's entry list, freeing each entry's attached block and then the entry.
pub fn func_800CF1A8() callconv(.c) void {
    var cur: ?*v.D_800F53B8_t = v.g.D_800F53B8().*;
    _ = c.func_800434A4(0, 1);

    while (cur) |s0| {
        const next = psx.get(s0.next);
        if (psx.get(s0.unkD1C.unk30)) |block| {
            c.vs_main_freeHeapR(block);
            psx.put(&s0.unkD1C.unk30, null);
        }
        c.func_800CE8F4(@ptrCast(s0));
        cur = next;
    }
}
