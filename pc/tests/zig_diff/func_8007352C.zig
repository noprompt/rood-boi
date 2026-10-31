//! zig_diff spec: func_8007352C -> func_8007352C.func_8007352C (146C.c).
//! The C body has no arguments and no branches: it stores 6 to D_800F196C
//! and calls func_8006C39C. The inputs are the random state the harness
//! fills in; what varies is the global's prior value (6 in about a quarter
//! of the runs, random otherwise) and what the callee writes back. The stub
//! rewrites D_800F196C with a stub-drawn value, as the real callee may, so a
//! port that reorders the store across the call, or drops it, differs in the
//! state hash the call records.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007352C));

pub const classes = [_][:0]const u8{ "already-6", "other" };

pub const stubs = struct {
    pub fn func_8006C39C(ctx: *zd.Ctx) void {
        v.g.D_800F196C().* = ctx.value(u32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(4)) v.g.D_800F196C().* = 6;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F196C().* == 6) 0 else 1;
}
