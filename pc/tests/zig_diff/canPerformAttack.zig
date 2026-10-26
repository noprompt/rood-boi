//! zig_diff spec: _canPerformAttack -> can_perform_attack.canPerformAttack (146C.c).
//! Inputs: an action in the arena whose hitParams entries -5..5 (the bytes
//! around and inside the struct, as the C indexes them) hold a random
//! prerequisiteFunction, 1 one time in three and 0-39 otherwise (the C calls
//! table entries 0-39 only); an arg1 buffer whose byte 3 is 4 half the time;
//! and a hitNumber from the edges 0 and +-1..5. The prerequisite table's
//! entries 0-39 point at two stubs that write arg1 and return values from it.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").canPerformAttack));

pub const classes = [_][:0]const u8{ "hit-zero", "guarded", "prereq-one-other-arg", "table-call" };

/// hitParams[k] of an action (k may be negative: the C indexes it as C does).
fn hitParam(action: *v.vs_action_t, k: c_int) *align(1) v.vs_action_t_hitParams {
    return psx.byteAt(
        v.vs_action_t_hitParams,
        action,
        @as(isize, @offsetOf(v.vs_action_t, "hitParams")) + @as(isize, @sizeOf(v.vs_action_t_hitParams)) * @as(isize, k),
    );
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    const arg1 = ctx.allocBytes(16, 1);
    arg1[3] = if (ctx.chance(2)) 4 else ctx.int(u8);

    var k: c_int = -5;
    while (k <= 5) : (k += 1) {
        const pf: u6 = if (ctx.chance(3)) 1 else ctx.range(u6, 0, 39);
        psx.setBits(hitParam(action, k), "prerequisiteFunction", pf);
    }

    const tbl = v.g._attackPrerequisiteFunctions();
    for (0..40) |i| {
        const f: ?*const anyopaque = if (i % 2 == 0) @ptrCast(&prereqA) else @ptrCast(&prereqB);
        tbl[i] = f;
    }

    const hit = ctx.edge(c_int, &.{ 0, 0, 1, 2, 3, 4, 5, -1, -2, -3, -4, -5 });
    return .{ action, arg1, hit };
}

pub fn classify(args: Args) usize {
    const hit = args[2];
    if (hit == 0) return 0;
    const hp = hitParam(args[0].?, hit);
    if (psx.getBits(hp, "prerequisiteFunction") != 1) return 3;
    return if (args[1][3] == 4) 1 else 2;
}

/// Table entry stub: writes arg1 (the callee may change it) and returns a value from it.
fn prereqA(action: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    arg1[1] = arg1[0] +% @as(u8, action.?.id);
    return @as(i8, @bitCast(arg1[0]));
}

/// Second table entry stub: a different write and a negative return.
fn prereqB(action: ?*v.vs_action_t, arg1: [*c]u8) callconv(.c) c_int {
    arg1[2] = ~arg1[1];
    return @as(c_int, action.?.id) -% 300;
}
