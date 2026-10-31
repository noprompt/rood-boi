//! Interpolates a value from the segment table in block 11 of D_800F569C (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");

/// orig: func_800D11F4 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Walks table `index` of block 11 past the segments `value` covers and interpolates within the last one.
pub fn func_800D11F4(index: c_int, value: c_int) callconv(.c) c_int {
    const buf = psx.get(v.g.D_800F569C().*.?.block11Data).?;
    const table: *align(1) v.pFileBlock11 = @ptrCast(buf);
    var offset: c_int = undefined;
    var remaining: c_int = value;

    if (index < table.count) {
        offset = @as(c_int, psx.at(&table.offsets, index).*);
        offset +%= @as(c_int, psx.at(buf, offset).*);
        while (psx.at(buf, offset).* != 0) {
            const v_: c_int = remaining -% @as(c_int, psx.at(buf, offset).*);
            if (v_ < 0) {
                break;
            }
            offset +%= 2;
            remaining = v_;
        }
        if (psx.at(buf, offset).* != 0) {
            // The divisor is a u8 promoted to int and nonzero here: no trap.
            return @divTrunc((@as(c_int, psx.at(buf, offset +% 3).*) -% @as(c_int, psx.at(buf, offset +% 1).*)) *% remaining, @as(c_int, psx.at(buf, offset).*)) +% @as(c_int, psx.at(buf, offset +% 1).*);
        }
        if (remaining == 0) {
            return @as(c_int, psx.at(buf, offset +% 1).*);
        }
        return -1;
    }
    return 0;
}
