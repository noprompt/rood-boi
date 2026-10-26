//! zig_diff spec: func_800771E0 -> func_800771E0.func_800771E0 (146C.c).
//! Inputs: an object buffer (arg0) in the arena, so arg0[37] is a random
//! byte, and three ints (arg1, arg2, arg3) drawn from edge sets that hit
//! arg1 == 2 (the `< 2` / `>= 2` boundary), arg2 zero and nonzero, and arg3
//! with each low two bits (`(arg3 & 3) == 1` both ways). The populate stub
//! copies the fields the C sets (dataType, index, modelId, actorId) into an
//! arena log, so a wrong index or modelId shows up in the compared state.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800771E0));

pub const classes = [_][:0]const u8{ "skip-first-clause", "skip-second-clause", "enter-index-below-2", "enter-index-at-least-2" };

/// Arena block the populate stub writes the slot's fields into (set by prepare).
var log: ?*v.vs_battle_objectData = null;

pub const stubs = struct {
    pub fn vs_battle_populateDataSlot(ctx: *zd.Ctx, p: anytype) c_int {
        const src: *const v.vs_battle_objectData = @ptrCast(@alignCast(p));
        if (log) |dst| {
            dst.dataType = src.dataType;
            dst.index = src.index;
            dst.modelId = src.modelId;
            dst.actorId = src.actorId;
        }
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const buf = ctx.allocBytes(64, 16);
    log = ctx.alloc(v.vs_battle_objectData);
    const arg1 = ctx.pick(c_int, &.{ 0, 1, 2, 3, -1, 2, std.math.minInt(c_int), std.math.maxInt(c_int) });
    const arg2 = ctx.pick(c_int, &.{ 0, 1, -1, 2, 4, std.math.minInt(c_int) });
    const arg3 = ctx.pick(c_int, &.{ 0, 1, 2, 3, 5, -3, -1, 7 });
    return .{ buf, arg1, arg2, arg3 };
}

pub fn classify(args: Args) usize {
    const arg1 = args[1];
    const arg2 = args[2];
    const arg3 = args[3];
    const first = arg2 != 0 or arg1 >= 2;
    if (!first) return 0;
    const second = arg1 < 2 or (arg3 & 3) == 1;
    if (!second) return 1;
    return if (arg1 < 2) 2 else 3;
}
