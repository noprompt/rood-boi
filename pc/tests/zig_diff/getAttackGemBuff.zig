//! zig_diff spec: _getAttackGemBuff -> get_attack_gem_buff.getAttackGemBuff (146C.c).
//! Inputs: a random action (type 0-7, so spell and non-spell both occur) and an
//! actor whose unk957 slot (0-15) holds an arena owner in vs_battle_actors. The
//! owner's weaponDrawn is random with bit 0 set or cleared, so both the
//! `& 1` test and the nonzero test a porter might write see differences. Each
//! of the three gems takes one of 0, 1, 2, 3 or 255, so the gem match occurs
//! at every index, for either effect value, and with or without a match.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getAttackGemBuff));

pub const classes = [_][:0]const u8{ "not-drawn", "spell-buff", "spell-no-buff", "weapon-buff", "weapon-no-buff" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const action = ctx.alloc(v.vs_action_t);
    const actor = ctx.alloc(v.vs_battle_actor2);
    const owner = ctx.alloc(v.vs_battle_actor);

    // The C indexes the 16-entry table with unk957 and reads only that entry.
    const slot = ctx.range(u8, 0, 15);
    actor.unk957 = slot;
    v.g.vs_battle_actors()[slot] = owner;

    // Drawn (bit 0 set) three times in four; the other bits are random.
    const w = ctx.int(i32);
    owner.weaponDrawn = if (ctx.chance(4)) (w & ~@as(i32, 1)) else (w | 1);

    psx.setBits(action, "type", ctx.pick(u3, &.{ 0, 1, 2, 7 }));

    for (0..3) |i| {
        actor.weapon.gems[i].gemEffects = ctx.edge(u8, &.{ 0, 1, 2, 3, 255 });
    }

    return .{ action, actor };
}

pub fn classify(args: Args) usize {
    const action = args[0].?;
    const actor = args[1].?;
    const owner = v.g.vs_battle_actors()[actor.unk957];
    if ((owner.?.weaponDrawn & 1) == 0) return 0;
    const spell = psx.getBits(action, "type") == 1;
    const want: u8 = if (spell) 2 else 1;
    var hit = false;
    for (actor.weapon.gems) |gem| {
        if (gem.gemEffects == want) hit = true;
    }
    if (spell) return if (hit) 1 else 2;
    return if (hit) 3 else 4;
}
