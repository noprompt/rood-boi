//! zig_diff spec: _calculateWeaponClassAffinity -> calculate_weapon_class_affinity.calculateWeaponClassAffinity (146C.c).
//! Inputs: a vs_battle_actor2 in the arena with its random fill (every blade and gem
//! class and affinity byte, including negatives, and every unk168 entry). Some calls
//! bias the affinities to -128/127 and unk168 to the i16 extremes, so the per-slot
//! sum plus unk168 wraps the short the C stores. The C makes no calls and reads no
//! globals, so there are no stubs. Classes: "wraps" when some slot's affinity sum
//! plus unk168 leaves i16, "fits" otherwise.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").calculateWeaponClassAffinity));

pub const classes = [_][:0]const u8{ "wraps", "fits" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor2);
    if (ctx.chance(3)) {
        for (&actor.weapon.blade.affinities) |*x| x.* = ctx.pick(i8, &.{ 127, -128, 0 });
        for (&actor.weapon.gems) |*g| {
            for (&g.affinities) |*x| x.* = ctx.pick(i8, &.{ 127, -128, 0 });
        }
    }
    if (ctx.chance(3)) {
        for (&actor.weapon.unk168) |*x| x.* = ctx.pick(i16, &.{ 32767, -32768, 0, -1 });
    }
    return .{actor};
}

pub fn classify(args: Args) usize {
    const a = args[0].?;
    var k: usize = 0;
    while (k < 7) : (k += 1) {
        const s: i32 = @as(i32, a.weapon.blade.affinities[k]) + a.weapon.gems[0].affinities[k] + a.weapon.gems[1].affinities[k] + a.weapon.gems[2].affinities[k];
        const t: i32 = s + a.weapon.unk168[k];
        if (t < -32768 or t > 32767) return 0;
    }
    return 1;
}
