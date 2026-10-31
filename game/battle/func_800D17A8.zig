//! Lerps a vector from arg0 toward arg1 by arg2 into arg3 (src/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D17A8 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Interpolates each component of arg0 toward arg1 by arg2 (vs_battle_lerp) into arg3.
pub fn func_800D17A8(arg0: ?*v.VECTOR, arg1: ?*v.VECTOR, arg2: c_int, arg3: ?*v.VECTOR) callconv(.c) void {
    arg3.?.vx = c.vs_battle_lerp(arg0.?.vx, arg1.?.vx, arg2);
    arg3.?.vy = c.vs_battle_lerp(arg0.?.vy, arg1.?.vy, arg2);
    arg3.?.vz = c.vs_battle_lerp(arg0.?.vz, arg1.?.vz, arg2);
}
