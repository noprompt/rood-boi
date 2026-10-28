//! zig_diff spec: func_8006F848 -> func_8006F848.func_8006F848 (146C.c).
//! Inputs: none. The body is straight-line with no branch and reads no
//! global, so every run takes the same path. What varies is the callee's
//! side: `func_800CF3F8` is modelled as copying its request into an arena
//! block the spec owns (the "sink", standing in for the globals the real
//! callee copies it into), and returning an arbitrary `c_int`. The sink is
//! compared as state, so a field the port writes wrongly, or a call it
//! drops or makes with the wrong flag, shows up in the copied request.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006F848));

pub const classes = [_][:0]const u8{"call"};

/// Arena block the callee stub copies the request into; set by prepare.
var sink: ?*v.func_800CF0E8_t = null;

pub const stubs = struct {
    pub fn func_800CF3F8(ctx: *zd.Ctx, req: anytype, flag: anytype) c_int {
        _ = flag;
        const r: *v.func_800CF0E8_t = @ptrCast(@alignCast(req));
        if (sink) |s| s.* = r.*;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    sink = ctx.alloc(v.func_800CF0E8_t);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
