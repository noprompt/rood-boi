//! zig_diff spec: _triggerClassChange -> trigger_class_change.triggerClassChange (146C.c).
//! Inputs: a random uiEquipment whose class bytes sit on the edges -128, -101,
//! -100, -99, 98, 99, 100 and 127 (plus random bytes), a target class 0-5 with
//! its class capped at 100 or not, and actorId 0 or not. Classes 6 and 7 occur
//! only with the target already capped above 100 (101 or 127): the C's switch
//! has no default, so the opposing classes are uninitialised for them and must
//! not be read. The vs_main_getRand stub returns mostly thresholds in 20..75
//! (so the roll comparisons hit equality) and sometimes any int;
//! func_80096768 sometimes writes a random class byte into the equipment, a
//! change the C reads back.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").triggerClassChange));

pub const classes = [_][:0]const u8{ "capped", "actor-not-zero", "opp0-floor", "rolls" };

/// The equipment the current iteration built; the stubs read and write it.
var eq_ptr: ?*v.vs_battle_uiEquipment = null;

pub fn prepare(ctx: *zd.Ctx) Args {
    const eq = ctx.alloc(v.vs_battle_uiEquipment);
    eq_ptr = eq;
    const action: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    const cls: c_int = if (ctx.chance(5)) ctx.range(c_int, 6, 7) else ctx.range(c_int, 0, 5);
    for (&eq.classes) |*c| c.* = ctx.pick(i8, &.{ -100, -101, 99, 100, 127, -128, 0 });
    const t: usize = @intCast(cls);
    if (cls >= 6) {
        // Classes 6 and 7 are only ever capped strictly above 100, so the C
        // returns early and never reads the uninitialised opposing classes.
        eq.classes[t] = ctx.edge(i8, &.{ 101, 127 });
    } else if (ctx.chance(3)) {
        eq.classes[t] = ctx.edge(i8, &.{ 100, 127 });
    } else {
        eq.classes[t] = ctx.pick(i8, &.{ -101, -100, -99, 98, 99, 0, -128 });
    }
    const actorId: c_int = if (ctx.chance(2)) 0 else ctx.pick(c_int, &.{ 1, -1, 2 });
    const arg3 = ctx.int(c_int);
    return .{ action, eq, cls, arg3, actorId };
}

pub fn classify(args: Args) usize {
    const eq = args[1].?;
    const cls: usize = @intCast(args[2]);
    if (eq.classes[cls] >= 100) return 0;
    if (args[4] != 0) return 1;
    if (eq.classes[(cls + 1) % 6] <= -100) return 2;
    return 3;
}

pub const stubs = struct {
    pub fn vs_main_getRand(ctx: *zd.Ctx, n: anytype) c_int {
        _ = n;
        if (ctx.value(u8) < 32) return ctx.value(c_int);
        return 20 + @as(c_int, ctx.value(u8) % 56);
    }

    pub fn func_80096768(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) void {
        _ = a;
        _ = b;
        _ = c;
        const eq = eq_ptr orelse return;
        if (ctx.value(u8) < 64) eq.classes[ctx.value(u8) % 8] = ctx.value(i8);
    }
};
