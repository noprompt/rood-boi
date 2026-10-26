//! zig_diff spec: func_8007FE5C -> func_8007FE5C.func_8007FE5C (146C.c).
//! Inputs: an action with type spell (1) about half the time and other types
//! otherwise, and two actors whose weapon and shield gems carry effect codes
//! drawn from {0, 3, 4, 7, 8, 255}, so every gem slot can match or miss the
//! code the C tests for. arg1 takes the edges 0, +-1, +-100, and the i16
//! extremes, so the product with 95/100/105 is tested for sign and wrap. The
//! C calls no external functions and reads no globals.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007FE5C));

pub const classes = [_][:0]const u8{
    "spell-weapon-hit",
    "spell-no-weapon-hit",
    "other-weapon-hit",
    "other-no-weapon-hit",
};

const gem_codes = [_]u8{ 0, 3, 4, 7, 8, 255 };

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    const a2 = ctx.alloc(v.vs_battle_actor2);
    const a3 = ctx.alloc(v.vs_battle_actor2);

    const kind: u3 = if (ctx.chance(2)) 1 else ctx.edge(u3, &.{ 0, 2, 3, 4, 5, 6, 7 });
    psx.setBits(action, "type", kind);

    for (&a2.weapon.gems) |*g| g.gemEffects = ctx.edge(u8, &gem_codes);
    for (&a3.shield.gems) |*g| g.gemEffects = ctx.edge(u8, &gem_codes);

    const arg1 = ctx.pick(i16, &.{ 0, 1, -1, 100, -100, 32767, -32768 });
    return .{ action, arg1, a2, a3 };
}

pub fn classify(args: Args) usize {
    const action = args[0].?;
    const spell = psx.getBits(action, "type") == 1;
    const want: u8 = if (spell) 4 else 3;
    var hit = false;
    for (args[2].?.weapon.gems) |g| {
        if (g.gemEffects == want) hit = true;
    }
    if (spell) return if (hit) 0 else 1;
    return if (hit) 2 else 3;
}
