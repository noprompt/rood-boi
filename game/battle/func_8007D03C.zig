//! Battle actor check: runs the actor's assembly callee and clears a flag bit on a zero result (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007D03C (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the actor's check; on 0 clears bit 2 of the actor's flags and returns 1, else returns whether the check gave 2.
pub fn func_8007D03C(arg0: c_int) callconv(.c) c_int {
    // ROOD_PC: the assembly callee reads the actor id from $a0, so it is passed as arg0.
    const Check = *const fn (c_int) callconv(.c) c_int;
    const check: Check = @ptrCast(&c.func_800E5154);
    const temp_v0 = check(arg0);

    if (temp_v0 == 0) {
        const getFlags = @extern(*const fn (c_int) callconv(.c) c_int, .{ .name = "func_800A0A74" });
        const flags = getFlags(arg0);
        c.func_800A0A1C(arg0, flags & ~@as(c_int, 2));
        return 1;
    }
    return @as(c_int, @intFromBool(temp_v0 == 2));
}
