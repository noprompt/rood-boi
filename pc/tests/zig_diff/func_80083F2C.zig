//! zig_diff spec: func_80083F2C -> func_80083F2C.func_80083F2C (146C.c).
//! The C body is one call, `_setApplicableStatuses(0x15, arg2)`, with no
//! branches. The inputs vary arg2 between null and a hit entity in the arena
//! (the C never tests it, so null must reach the callee). The callee stub
//! writes the entity's status masks when it is given one and returns a
//! value from ctx. arg0, arg1, arg3 and arg4 are unused by the C but still
//! filled, so a port that reads them would be caught.
//!
//! The C has no return statement. Its result is whatever the callee left in
//! the return register, which is not something the spec can assume a port
//! reproduces: the stand-in copy of the C and the C itself disagreed on that
//! value on every iteration. So the spec makes the callee's return a fixed
//! constant (identical in every run), and the entity writes stay random.
//! Prepare draws only from ctx and touches no global.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80083F2C));

pub const classes = [_][:0]const u8{ "null-target", "entity-target" };

pub const stubs = struct {
    pub fn _setApplicableStatuses(ctx: *zd.Ctx, id: anytype, ent: anytype) c_int {
        _ = id;
        if (ent) |p| {
            const h: *v._hitEntity_t = @ptrCast(@alignCast(p));
            h.inflictStatuses = ctx.value(i32);
            h.removeStatuses = ctx.value(i32);
        }
        return 0;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const a0: ?*v.vs_action_t = if (ctx.chance(4)) null else ctx.alloc(v.vs_action_t);
    const a1: ?*v._hitEntity_t = if (ctx.chance(4)) null else ctx.alloc(v._hitEntity_t);
    const a2: ?*v._hitEntity_t = if (ctx.chance(3)) null else ctx.alloc(v._hitEntity_t);
    return .{ a0, a1, a2, 0, 0 };
}

pub fn classify(args: Args) usize {
    return if (args[2] == null) 0 else 1;
}
