//! zig_diff spec: _hitPrerequisiteCanApplyAirAttackUp -> hit_prerequisite_can_apply_air_attack_up.hitPrerequisiteCanApplyAirAttackUp (146C.c).
//! Inputs: an index 0-15 into vs_battle_actors, which has 16 arena actors,
//! each with its own stats block whose blade id is 0 or nonzero (including
//! 0x8000 and 0xFFFF), and an action that is null or an arena object (unused).
//! The effect check is a recording stub that returns zero or any c_int
//! (negative and positive included), and it sometimes rewrites the index
//! byte and the blade id of the entry, which the C reads back after the call.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyAirAttackUp));

pub const classes = [_][:0]const u8{ "blade-zero", "blade-nonzero" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: c_int, arg1: [*c]u8) c_int {
        _ = arg0;
        const r: c_int = if (ctx.value(u8) < 128) 0 else ctx.value(c_int);
        // The callee may change the index the C reads back after the call.
        if (ctx.value(u8) < 64) {
            arg1[0] = ctx.value(u8) % 16;
        }
        // The callee may change the blade id of the entry it names.
        if (ctx.value(u8) < 64) {
            const a = v.g.vs_battle_actors()[arg1[0]] orelse return r;
            const st = psx.get(a.stats) orelse return r;
            st.weapon.blade.id = ctx.value(u16);
        }
        return r;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    var i: usize = 0;
    while (i < 16) : (i += 1) {
        const actor = ctx.alloc(v.vs_battle_actor);
        const stats = ctx.alloc(v.vs_battle_actor2);
        psx.put(&actor.stats, stats);
        stats.weapon.blade.id = ctx.pick(u16, &.{ 0, 0, 1, 0x8000, 0xFFFF });
        table[i] = actor;
    }
    const action: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    const idx = ctx.alloc(u8);
    idx.* = ctx.range(u8, 0, 15);
    const arg1: [*c]u8 = idx;
    return .{ action, arg1 };
}

pub fn classify(args: Args) usize {
    const actor = v.g.vs_battle_actors()[args[1][0]] orelse return 0;
    const stats = psx.get(actor.stats) orelse return 0;
    return if (stats.weapon.blade.id == 0) 0 else 1;
}
