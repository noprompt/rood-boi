//! zig_diff spec: func_80085390 -> func_80085390.func_80085390 (146C.c).
//! Inputs: an action with a random type 0-7 and hitParams effects 0-69 (the
//! mediator table's size), hit 0 or 1, arg3 of 0, 1 or -1, and two hit
//! entities: arg2 targets actor 0-15 (0 a fifth of the time), arg1 mostly
//! targets actor 0. The sixteen battle actors each have their own stats with
//! the 0x80 unit flag sometimes, statuses on the 0x80040000 and 0x61000 bits
//! or none, and currentHP equal to arg2's hp for the target sometimes. The
//! character's weapon category and the arts tables are set so the kill
//! counter both increments and stops. Every _actionEffectMediators entry is
//! `mediator`, a C-callable effect that moves arg2's hp by hit, adds to
//! _lastValue, and in some runs sets the target's unit flag (unk957 = 0x80),
//! so the C and the port must both re-read the target after the call. The
//! flag write covers the spell path's second unit-flag test, which only a
//! mediator can flip. vs_battle_getStateFlag returns 0-13, so the `>= 0xA`
//! test sees equality.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80085390));

pub const classes = [_][:0]const u8{ "dead-target", "spell-status-skip", "spell-mediated", "mediated-other", "arts-block" };

/// Set by prepare each iteration: the mediator flips the target's unit flag.
var mediator_sets_unit: bool = false;

/// Stands in for every _actionEffectMediators entry.
fn mediator(action: ?*anyopaque, arg1: ?*anyopaque, arg2: ?*anyopaque, hit: c_int, arg3: c_int) callconv(.c) void {
    _ = action;
    _ = arg1;
    const target: *v._hitEntity_t = @ptrCast(@alignCast(arg2.?));
    target.unk0.hp +%= @as(i16, @truncate(hit));
    v.g._lastValue().* +%= @as(u32, @bitCast(arg3)) +% 7;
    if (mediator_sets_unit) {
        const actor = v.g.vs_battle_actors()[target.unk0.targetActor].?;
        psx.get(actor.stats).?.unk957 = 0x80;
    }
}

pub const stubs = struct {
    pub fn vs_battle_getStateFlag(ctx: *zd.Ctx, flag: anytype) u8 {
        _ = flag;
        return ctx.value(u8) % 14;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    const arg1 = ctx.alloc(v._hitEntity_t);
    const arg2 = ctx.alloc(v._hitEntity_t);
    const charActor = ctx.alloc(v.vs_battle_actor);

    mediator_sets_unit = ctx.chance(3);

    // Every effect index the C can read (0..69) calls the mediator.
    const med = v.g._actionEffectMediators();
    for (0..70) |i| med[i] = @ptrCast(&mediator);

    psx.setBits(action, "type", ctx.edge(u3, &.{ 0, 1, 1, 2, 3, 3, 4, 5, 6, 6, 7 }));
    for (&action.hitParams) |*hp| psx.setBits(hp, "effect", ctx.range(u7, 0, 69));
    const hit: c_int = ctx.edge(c_int, &.{ 0, 1 });
    const arg3: c_int = ctx.pick(c_int, &.{ 0, 1, -1 });

    arg1.unk40 = if (ctx.chance(4)) 1 else 0;
    arg1.unk0.targetActor = if (ctx.chance(3)) ctx.range(u8, 1, 15) else 0;

    arg2.unk40 = if (ctx.chance(4)) 1 else 0;
    arg2.unk0.targetActor = if (ctx.chance(5)) 0 else ctx.range(u8, 1, 15);
    arg2.unk0.hp = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });

    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        const st = ctx.alloc(v.vs_battle_actor2);
        psx.put(&actor.stats, st);
        actor.unk29 = if (ctx.chance(3)) 1 else 0;
        st.unk957 = if (ctx.chance(3)) 0x80 else ctx.pick(u8, &.{ 0x7F, 0x81, 0xFF });
        st.statuses = ctx.pick(i32, &.{ 0, 0x40000, std.math.minInt(i32), 0x1000, 0x61000, -1 });
        st.currentHP = ctx.pick(i16, &.{ 0, 1, -1, 32767 });
        table[i] = actor;
    }
    // The target's currentHP equals its hp sometimes (the `<=` edge).
    const target = table[arg2.unk0.targetActor].?;
    if (ctx.chance(2)) psx.get(target.stats).?.currentHP = arg2.unk0.hp;

    charActor.equippedWeaponCategory = ctx.pick(u8, &.{ 0, 9, 10, 19, 255 });
    v.g.vs_battle_characterState().* = charActor;
    const t: usize = charActor.equippedWeaponCategory % 10;
    const ms = v.g.vs_main_artsStatus();
    const req = v.g.vs_main_artsPointsRequirements();
    ms.artsLearned[t] = ctx.edge(u8, &.{ 0, 1, 3, 4, 11 });
    const learned = ms.artsLearned[t];
    if (learned < 4) {
        if (ctx.chance(2)) ms.kills.weaponCategories[t] = req[t][learned];
        if (ctx.chance(4)) req[t][learned] = ctx.pick(u16, &.{ 0, 1, 65535 });
    }

    return .{ action, arg1, arg2, arg3, hit };
}

pub fn classify(args: Args) usize {
    const action = args[0].?;
    const arg1 = args[1].?;
    const arg2 = args[2].?;
    const actor = v.g.vs_battle_actors()[arg2.unk0.targetActor].?;
    const stats = psx.get(actor.stats).?;
    if (arg2.unk40 == 0 and stats.unk957 == 0x80) return 0;
    const t = psx.getBits(action, "type");
    if (t == 1) {
        const status_bits = @as(u32, @bitCast(stats.statuses)) & 0x80040000;
        return if (arg2.unk40 == 0 and status_bits != 0) 1 else 2;
    }
    const block = args[3] != 0 and arg1.unk40 == 0 and arg1.unk0.targetActor == 0 and
        arg2.unk40 == 0 and stats.unk957 != 0x80 and (t == 2 or t == 3 or t == 6) and
        stats.currentHP <= arg2.unk0.hp and arg2.unk0.targetActor != 0 and actor.unk29 == 0;
    return if (block) 4 else 3;
}
