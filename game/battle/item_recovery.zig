//! Item recovery amount: the hit's stat factor scaled by 5, with a smoothed random
//! spread when the action asks for one (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _itemRecovery (src/BATTLE/BATTLE.PRG/146C.c)
/// Returns the recovery for hit parameter `arg3`: five times its stat factor, plus a random spread of -5..6 when `arg4` is nonzero, clamped at 0.
pub fn itemRecovery(arg0: ?*v.vs_action_t, _: ?*v._hitEntity_t, _: ?*v._hitEntity_t, arg3: c_int, arg4: c_int) callconv(.c) c_short {
    const action = arg0.?;
    // arg3 is not checked against the two hit parameters, as in the C.
    const hitParam = psx.at(&action.hitParams, arg3);
    var temp_s0: i16 = psx.conv(i16, @as(c_int, psx.getBits(hitParam, "statFactor")) *% 5);

    const temp_v0: i16 = if (arg4 != 0)
        psx.conv(i16, c.vs_main_getRandSmoothed(0xB) -% 5)
    else
        0;

    temp_s0 = psx.conv(i16, @as(c_int, temp_s0) +% @as(c_int, temp_v0));

    if (temp_s0 < 0) {
        temp_s0 = 0;
    }

    return temp_s0;
}
