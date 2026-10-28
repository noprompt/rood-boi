//! zig_diff spec: _factorPhysicalDamageReceived0 -> factor_physical_damage_received0.factorPhysicalDamageReceived0 (146C.c).
//! Inputs: a battle action in the arena with a padded arena so that
//! `action->hitParams[arg3]` stays in memory for arg3 in [-512, 512]; the
//! D_800F19CC block with an action index in 0..255 (vs_main_actions is only
//! read inside its 256 entries), whose action type is the spell type (1) or
//! any other 3-bit value, and whose hpEffect is 0..3 (1 and 3 take the
//! damage branch, 0 and 2 do not). hp and mp are edge values (0, +-1, the
//! i16 extremes), so their sum and the scaled product wrap the short result.
//! The C makes no calls, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").factorPhysicalDamageReceived0));

pub const classes = [_][:0]const u8{ "spell-action", "hp-effect-1", "hp-effect-3", "hp-effect-other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    // Room before the action so that negative hitParams indices stay in the arena.
    _ = ctx.allocBytes(4096, 16);
    const action = ctx.alloc(v.vs_action_t);
    const arg1: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);
    const arg2: ?*v._hitEntity_t = if (ctx.chance(2)) null else ctx.alloc(v._hitEntity_t);

    const d = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = d;
    d.unk8.actionIndex = if (ctx.chance(2))
        ctx.range(u16, 0, 255)
    else
        ctx.edge(u16, &.{ 0, 1, 2, 127, 128, 255 });

    const actions = v.g.actions();
    const spell = ctx.chance(3);
    psx.setBits(&actions[d.unk8.actionIndex], "type", if (spell) 1 else ctx.range(u3, 0, 7));

    psx.setBits(&d.unk8.unk4, "hpEffect", ctx.range(u2, 0, 3));
    d.unk8.unk4.unk0.hp = ctx.pick(i16, &.{ 0, 1, -1, 100, 32767, -32768 });
    d.unk8.unk4.unk0.mp = ctx.pick(i16, &.{ 0, 1, -1, 100, 32767, -32768 });

    const arg3: c_int = if (ctx.chance(2)) ctx.edge(c_int, &.{ 0, 1 }) else ctx.range(c_int, -512, 512);
    const arg4: c_int = ctx.range(c_int, -512, 512);

    return .{ action, arg1, arg2, arg3, arg4 };
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F19CC().*.?;
    const actions = v.g.actions();
    if (psx.getBits(&actions[d.unk8.actionIndex], "type") == 1) return 0;
    return switch (psx.getBits(&d.unk8.unk4, "hpEffect")) {
        1 => 1,
        3 => 2,
        else => 3,
    };
}
