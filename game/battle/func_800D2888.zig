//! Unlinks an entry from its doubly linked list and pushes it onto the free list
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

/// orig: func_800D2888 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Unlinks `arg0` from its list, pushes it onto the free list and updates both counts.
pub fn func_800D2888(arg0: ?*v.func_800D2904_t, arg1: ?*v.D_800F53B8_t) callconv(.c) void {
    const self = arg0.?;
    const owner = arg1.?;

    if (psx.get(self.next)) |next| {
        next.previous = self.previous;
    }

    if (psx.get(self.previous)) |prev| {
        prev.next = self.next;
    } else {
        owner.unk18 = self.next;
    }

    psx.put(&self.next, v.g.D_800F55F4().*);
    v.g.D_800F55F4().* = self;
    v.g.D_800F55F8().* -%= 1;
    owner.unk8 -%= 1;
}
