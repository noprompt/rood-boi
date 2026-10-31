//! zig_diff spec: _hitPrerequisiteCanApplyFireAttackUp -> hit_prerequisite_can_apply_fire_attack_up.hitPrerequisiteCanApplyFireAttackUp (146C.c).
//! Inputs: sixteen actors in the vs_battle_actors table, each with a stats
//! block whose blade id is 0 or any u16 (sign bit included), and an index byte
//! that is in range (0-15) or out of range (16-255). The effect callee is a
//! stub that returns 0 or any c_int (sign bit included). It returns 7 for an
//! out-of-range index, so the C never reads past the table, and sometimes
//! retargets the index (kept below 16) before returning 0, so the C's re-read
//! of the index and the actor is tested.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").hitPrerequisiteCanApplyFireAttackUp));

pub const classes = [_][:0]const u8{ "index-out-of-range", "blade-id-zero", "blade-id-nonzero" };

pub const stubs = struct {
    pub fn _hitPrerequisiteCanApplyEffect(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) c_int {
        _ = arg0;
        if (arg1[0] >= 16) return 7;
        if (ctx.value(u8) < 128) {
            // The callee may retarget the index the C re-reads (kept in range).
            arg1[0] = ctx.value(u8) & 15;
            return 0;
        }
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        const stats = ctx.alloc(v.vs_battle_actor2);
        stats.weapon.blade.id = if (ctx.chance(3)) 0 else ctx.pick(u16, &.{ 1, 0x7FFF, 0x8000, 0xFFFF });
        psx.put(&actor.stats, stats);
        table[i] = actor;
    }

    const idx: u8 = if (ctx.chance(4))
        ctx.edge(u8, &.{ 16, 17, 127, 128, 255 })
    else
        ctx.range(u8, 0, 15);
    const byte = ctx.allocBytes(1, 1);
    byte[0] = idx;

    const action: ?*v.vs_action_t = if (ctx.chance(2)) null else ctx.alloc(v.vs_action_t);
    return .{ action, byte };
}

pub fn classify(args: Args) usize {
    const idx = args[1][0];
    if (idx >= 16) return 0;
    const actor = v.g.vs_battle_actors()[idx].?;
    const stats = psx.get(actor.stats).?;
    return if (stats.weapon.blade.id == 0) 1 else 2;
}
