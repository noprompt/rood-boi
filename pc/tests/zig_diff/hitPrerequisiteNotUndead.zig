//! zig_diff spec: _hitPrerequisiteNotUndead -> hit_prerequisite_not_undead.hitPrerequisiteNotUndead (146C.c).
//! Inputs: arg0 (unused by the C) null or an arena action, arg1 a random name
//! buffer in the arena (sometimes null, which the C never tests). The C only
//! calls _getEnemyClass(arg1) and compares its result with enemyClassUndead (2).
//! The stub returns 2 about a quarter of the time, so both sides of the
//! comparison occur, and any other c_int otherwise (negative and wrapping
//! values included). The stub only reads its argument and writes nothing:
//! the name lookup does not change the buffer or any global the C reads back.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteNotUndead));

pub const classes = [_][:0]const u8{ "arg0-null", "arg0-set" };

pub const stubs = struct {
    pub fn _getEnemyClass(ctx: *zd.Ctx, p: anytype) c_int {
        _ = p;
        // Undead (2) a quarter of the time, any other class otherwise.
        if (ctx.value(u2) == 0) return 2;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    const name: [*c]u8 = if (ctx.chance(8))
        null
    else
        @ptrCast(ctx.allocBytes(24, 1));
    return .{ action, name };
}

pub fn classify(args: Args) usize {
    return if (args[0] == null) 0 else 1;
}
