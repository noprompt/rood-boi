//! zig_diff spec: func_800CB79C -> func_800CB79C.func_800CB79C (5BF94.c).
//! Inputs: D_800EB9B4 is either NULL or points at an arena object. Only the
//! NULL case runs the body: it stores the address of D_800F4ED8 into
//! D_800EB9B4, then calls func_8007E180(6) and _loadScreff2(1). Both branches
//! are covered, and the stores and call arguments are compared through the
//! state bytes and the call traces.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CB79C));

pub const classes = [_][:0]const u8{ "null", "set" };

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(2)) {
        v.g.D_800EB9B4().* = null;
    } else {
        v.g.D_800EB9B4().* = ctx.alloc(v.D_800EB9B4_t);
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800EB9B4().* == null) 0 else 1;
}
