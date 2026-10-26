//! zig_diff spec: func_8007D3F8 -> func_8007D3F8.func_8007D3F8 (146C.c).
//! The C has no branches and no value edges: it stores NULL into
//! D_800F1ABC and calls func_8007D360. The inputs cover the global's
//! starting value (a live arena object or NULL, set by prepare), and the
//! callee's effect on the global: its stub either leaves it alone or clears
//! it. The checks are the store, the call, and their order.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007D3F8));

pub const classes = [_][:0]const u8{ "null-start", "live-start" };

pub const stubs = struct {
    /// The callee may change D_800F1ABC: it either leaves it or clears it.
    pub fn func_8007D360(ctx: *zd.Ctx) void {
        if (ctx.value(bool)) v.g.D_800F1ABC().* = null;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    // Both starting values are set explicitly, so each class occurs; the
    // store is observable whatever the starting pointer was.
    if (ctx.chance(2)) {
        v.g.D_800F1ABC().* = ctx.alloc(v.D_800F1ABC_t);
    } else {
        v.g.D_800F1ABC().* = null;
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (v.g.D_800F1ABC().* == null) 0 else 1;
}
