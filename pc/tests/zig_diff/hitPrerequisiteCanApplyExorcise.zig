//! zig_diff spec: _hitPrerequisiteCanApplyExorcise -> hit_prerequisite_can_apply_exorcise.hitPrerequisiteCanApplyExorcise (146C.c).
//! Inputs: an optional action (unused by the C) and an optional 4-byte buffer
//! passed to both callees. A spec-level mode, drawn in prepare, picks the path:
//! mode 0 makes the effect check return a nonzero value (short-circuit, with
//! values such as 0x100 whose low byte is 0), mode 1 makes the effect check
//! return 0 and the class come back as undead (2), and mode 2 makes the class
//! come back as any other value, including 0x102 whose low byte is 2. The stubs
//! also write the buffer, which the C never reads back.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyExorcise));

pub const classes = [_][:0]const u8{ "effect-nonzero", "undead", "not-undead" };

var mode: u8 = 0;

pub fn prepare(ctx: *zd.Ctx) Args {
    mode = ctx.range(u8, 0, 2);
    const action: ?*v.vs_action_t = if (ctx.chance(4)) null else ctx.alloc(v.vs_action_t);
    const buf: [*c]u8 = if (ctx.chance(10)) null else @ptrCast(ctx.allocBytes(4, 1));
    return .{ action, buf };
}

pub fn classify(args: Args) usize {
    _ = args;
    return mode;
}

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        if (arg1 != null) arg1[0] = ctx.value(u8);
        if (mode == 0) {
            const r = ctx.value(c_int);
            return if (r == 0) 0x100 else r;
        }
        return 0;
    }

    pub fn _getEnemyClass(ctx: *zd.Ctx, arg0: anytype) c_int {
        if (arg0 != null) arg0[0] = ctx.value(u8);
        if (mode == 1) return 2;
        const r = ctx.value(c_int);
        return if (r == 2) 0x102 else r;
    }
};
