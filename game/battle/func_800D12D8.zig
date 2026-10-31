//! Block 11 lookup: sums the zero-terminated byte run that an index entry
//! selects (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");

/// orig: func_800D12D8 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Sums the zero-terminated byte run that block 11's index entry `arg0` selects, plus one; 0 past the table's count.
pub fn func_800D12D8(arg0: c_int) callconv(.c) c_int {
    const bytes: [*]align(1) u8 = @ptrCast(psx.get(v.g.D_800F569C().*.?.block11Data).?);
    var sum: c_int = 0;

    if (arg0 < psx.byteAt(c_int, bytes, 0).*) {
        const shorts: [*]align(1) i16 = @ptrCast(bytes);
        var off: c_int = psx.at(shorts, arg0 +% 2).*;
        off +%= @as(c_int, psx.at(bytes, off).*);
        while (psx.at(bytes, off).* != 0) {
            sum +%= @as(c_int, psx.at(bytes, off).*);
            off +%= 2;
        }
        sum +%= 1;
    }
    return sum;
}
