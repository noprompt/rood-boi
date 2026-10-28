//! zig_diff spec: func_800735CC -> func_800735CC.func_800735CC (146C.c).
//! Inputs: one D_800F18EC_t in the arena with a random unk0 (zero, the
//! signed edges, or any i16) and a random unk2. The C has no branches; what
//! the inputs vary is the pre-call state the C overwrites: unk0 is stored as
//! 0 between two calls, so a port that drops, moves or retargets that store
//! changes the state hashed at the second call or the final state. The first
//! callee writes unk0 with ctx.value, the way a real callee may touch the
//! object it is handed, and the C's store must still win.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800735CC));

pub const classes = [_][:0]const u8{ "unk0-zero", "unk0-nonzero" };

/// The object prepare built for this iteration, so the callee stub can write it.
var current: ?*v.D_800F18EC_t = null;

pub const stubs = struct {
    pub fn func_800CB114(ctx: *zd.Ctx) void {
        if (current) |p| p.unk0 = ctx.value(i16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.D_800F18EC_t);
    obj.unk0 = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
    obj.unk2 = ctx.int(i16);
    current = obj;
    return .{obj};
}

pub fn classify(args: Args) usize {
    return if (args[0].?.unk0 == 0) 0 else 1;
}
