//! Replaces the 0x800-byte heap block held in D_800F1DD4 (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008E8F8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Frees the block at D_800F1DD4 if there is one, then allocates a new 0x800-byte block into it.
pub fn func_8008E8F8() callconv(.c) void {
    const block = v.g.D_800F1DD4();
    if (block.* != null) {
        c.vs_main_freeHeap(block.*);
    }
    const raw: ?*align(2) anyopaque = @alignCast(c.vs_main_allocHeap(0x800));
    block.* = @ptrCast(raw);
}
