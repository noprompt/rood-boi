//! zig_diff spec: func_800CB23C -> func_800CB23C.func_800CB23C (5BF94.c).
//! Inputs: none. The unit calls func_800CACD0(0xF, 2) and then stores 1 to
//! D_800F4FDB. The unit has no branches and no inputs to vary, so there is one
//! class. The callee's stub may overwrite D_800F4FDB (the C's store must
//! come after the call) and returns an arbitrary int, which the C ignores.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CB23C));

pub const classes = [_][:0]const u8{"call"};

pub const stubs = struct {
    pub fn func_800CACD0(ctx: *zd.Ctx, menuState: anytype, arg1: anytype) c_int {
        _ = menuState;
        _ = arg1;
        v.g.D_800F4FDB().* = ctx.value(u8);
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    _ = ctx;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
