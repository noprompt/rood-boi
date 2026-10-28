//! The last value the battle hit code stored (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: _getLastValue (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the low 16 bits of the stored last value, as a signed short.
pub fn getLastValue(_: ?*v.vs_action_t, _: ?*v._hitEntity_t, _: ?*v._hitEntity_t, _: c_int, _: c_int) callconv(.c) c_short {
    return psx.conv(c_short, v.g._lastValue().*);
}
