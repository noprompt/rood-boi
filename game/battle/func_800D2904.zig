//! Returns a chain of effect records to the free list and debits the free count
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

/// orig: func_800D2904 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Splices the owner's record chain onto the head of the free list, then debits the free count by the owner's count and clears it.
pub fn func_800D2904(arg0: ?*v.D_800F53B8_t) callconv(.c) void {
    const owner = arg0.?;
    const temp_a1 = psx.get(owner.unk18);
    var var_a0 = temp_a1;

    if (temp_a1 == null) {
        return;
    }

    while (psx.get(var_a0.?.next)) |n| {
        var_a0 = n;
    }

    psx.put(&var_a0.?.next, v.g.D_800F55F4().*);
    v.g.D_800F55F4().* = temp_a1;
    v.g.D_800F55F8().* -%= @as(c_int, owner.unk8);
    owner.unk8 = 0;
}
