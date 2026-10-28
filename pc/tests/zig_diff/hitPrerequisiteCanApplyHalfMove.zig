//! zig_diff spec: _hitPrerequisiteCanApplyHalfMove -> hit_prerequisite_can_apply_half_move.hitPrerequisiteCanApplyHalfMove (146C.c).
//! Inputs: arg0 is unused by the C, so it is null or a vs_action_t in the arena;
//! arg1 is a buffer in the arena or null (passed through to the callee). The
//! callee's stub returns each value the C's `== 0` test can see (0, 1, -1, 256,
//! 0x10000, and random bits), and sometimes writes the buffer it was given.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyHalfMove));

pub const classes = [_][:0]const u8{ "arg0-null", "arg0-set", "arg1-null" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(3)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(8)) null else ctx.allocBytes(16, 16);
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    if (args[1] == null) return 2;
    if (args[0] == null) return 0;
    return 1;
}

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        if (arg1 != null) {
            const p: [*]u8 = arg1;
            if (ctx.value(u1) == 1) p[0] = ctx.value(u8);
        }
        return switch (ctx.value(u3)) {
            0, 1 => 0,
            2 => 256,
            3 => -1,
            4 => 0x10000,
            5 => 1,
            else => ctx.value(c_int),
        };
    }
};
