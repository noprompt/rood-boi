//! zig_diff spec: func_8007CCAC -> func_8007CCAC.func_8007CCAC (146C.c).
//! The C only forwards the return value of vs_battle_getEmptyObjectDataSlot(),
//! so the inputs are the callee's answers: prepare picks the value the stub
//! returns (-1 for "no free slot", 0, a small positive slot, a negative other
//! than -1, and the int extremes). The stub draws nothing, so both runs see the
//! same answer. Classes name those answers; classify reads the same pick.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CCAC));

pub const classes = [_][:0]const u8{ "no-slot", "slot-zero", "slot-positive", "negative-other" };

/// The answer the stub returns this iteration (set by prepare).
var want: c_int = 0;

pub const stubs = struct {
    pub fn vs_battle_getEmptyObjectDataSlot(ctx: *zd.Ctx) c_int {
        _ = ctx;
        return want;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    want = ctx.pick(c_int, &.{ -1, 0, 1, 0x10000, std.math.maxInt(c_int), std.math.minInt(c_int) });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if (want == -1) return 0;
    if (want == 0) return 1;
    if (want > 0) return 2;
    return 3;
}
