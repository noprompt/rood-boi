//! zig_diff spec: _getDefenseGemBuff -> get_defense_gem_buff.getDefenseGemBuff (146C.c).
//! Inputs: an actor whose battle slot (unk957, 0-15) holds a battle actor in the
//! arena, with its weapon drawn or not (odd and even weaponDrawn, sign bit set
//! and clear); an action that is type 1 or not, with ids at the edges of the
//! id test (39, 40, 53, 54, 223, 224, 255); two hit parameters whose effects
//! are the switch's case values; three gems whose effects are the values the
//! gem tests compare against; hitNumber 0 and 1, plus -1 and 2, which read
//! inside the action object.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getDefenseGemBuff));

pub const classes = [_][:0]const u8{ "not-drawn", "type-1", "other-id-in", "other-id-out" };

const gem_effects = [_]u8{ 5, 6, 11, 12, 13, 14, 16, 18, 19, 21 };

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    const actor = ctx.alloc(v.vs_battle_actor2);
    const user = ctx.alloc(v.vs_battle_actor);

    const slot = ctx.range(u8, 0, 15);
    v.g.vs_battle_actors()[slot] = user;
    actor.unk957 = slot;

    user.weaponDrawn = ctx.pick(i32, &.{ 0, 1, 2, 3, -1, std.math.maxInt(i32), std.math.minInt(i32) });

    action.id = ctx.pick(u8, &.{ 0, 39, 40, 53, 54, 223, 224, 255 });
    psx.setBits(action, "type", ctx.pick(u3, &.{ 1, 1, 0, 2, 7 }));
    for (0..2) |h| {
        psx.setBits(&action.hitParams[h], "effect", ctx.pick(u7, &.{ 1, 2, 3, 5, 11, 15, 16, 17, 0, 127 }));
    }

    for (&actor.shield.gems) |*gem| {
        gem.gemEffects = ctx.pick(u8, &gem_effects);
    }

    const hit = ctx.edge(c_int, &.{ 0, 1, 0, 1, 2, -1 });

    // The C only reads the action inside the weapon-drawn branch, so a
    // not-drawn actor may be passed with no action.
    const act: ?*v.vs_action_t = if ((user.weaponDrawn & 1) == 0 and ctx.chance(2)) null else action;

    return .{ act, actor, hit };
}

pub fn classify(args: Args) usize {
    const actor = args[1].?;
    const user = v.g.vs_battle_actors()[actor.unk957].?;
    if ((user.weaponDrawn & 1) == 0) return 0;
    const action = args[0].?;
    if (psx.getBits(action, "type") == 1) return 1;
    const delta: u8 = action.id -% 54;
    return if (action.id < 40 or delta < 170) 2 else 3;
}
