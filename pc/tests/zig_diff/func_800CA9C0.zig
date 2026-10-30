//! zig_diff spec: func_800CA9C0 -> func_800CA9C0.func_800CA9C0 (5BF94.c).
//! The body has no branches and no comparisons: it stores zeros and constants
//! to globals, calls the memzero, the render, DrawSync and ClearOTag helpers,
//! and passes arg0 and arg0 offset by fixed amounts. The inputs vary arg0
//! between an arena block and the scratchpad address. Both are only passed on,
//! never dereferenced, so the C never faults. func_800CA97C may overwrite
//! D_800EB9D0, which the C's own store precedes, so a port that moves that store
//! across the call leaves a different final value.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CA9C0));

pub const classes = [_][:0]const u8{ "arena-pointer", "scratchpad-pointer" };

pub const stubs = struct {
    /// Writes a random value into D_800EB9D0 (the C stores 0xFFFFFF there
    /// before this call): a port that stores after the call disagrees.
    pub fn func_800CA97C(ctx: *zd.Ctx) void {
        v.g.D_800EB9D0().s32 = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(2)) {
        const p: *anyopaque = @ptrFromInt(zd.scratchpad);
        return .{p};
    }
    const p: *anyopaque = @ptrCast(ctx.allocBytes(1, 16));
    return .{p};
}

pub fn classify(args: Args) usize {
    return if (@intFromPtr(args[0].?) == zd.scratchpad) 1 else 0;
}
