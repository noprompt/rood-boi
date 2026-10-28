//! Scales the last value by an action's hit-parameter stat factor (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");

/// orig: _factorLastValue (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the last value times hit parameter `index`'s stat factor, divided by 10.
pub fn factorLastValue(action: ?*v.vs_action_t, _: ?*v._hitEntity_t, _: ?*v._hitEntity_t, index: c_int, _: c_int) callconv(.c) c_short {
    const hitParam = psx.at(&action.?.hitParams, index);
    const statFactor: c_uint = psx.getBits(hitParam, "statFactor");
    // unsigned * int promotes to unsigned int in C: the product wraps at 32 bits.
    const product: c_uint = v.g._lastValue().* *% statFactor;
    return psx.conv(c_short, product / 10);
}
