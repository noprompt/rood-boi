//! Packs an actor's status bits and their per-status display values into one word
//! (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");

/// orig: vs_battle_getStatusFlags (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns the low 16 status bits, with the table value of each set high status bit in the upper half.
pub fn getStatusFlags(arg0: ?*v.vs_battle_actor2) callconv(.c) c_int {
    const actor = arg0.?;
    var temp_v1: c_int = psx.conv(c_int, @as(c_uint, psx.conv(c_uint, actor.statuses)) >> 5);
    var var_a2: c_int = temp_v1 & 0xFFFF;
    temp_v1 >>= 16;

    const table = v.g.D_800EBC68();
    var i: u5 = 0;
    while (i < 8) : (i += 1) {
        if (((temp_v1 >> i) & 1) != 0) {
            // u16 promotes to int; the << 16 wraps into the sign bit as the C does.
            var_a2 |= @as(c_int, table[i]) << 16;
        }
    }

    return var_a2;
}
