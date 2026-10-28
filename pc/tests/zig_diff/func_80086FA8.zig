//! zig_diff spec: func_80086FA8 -> func_80086FA8.func_80086FA8 (146C.c).
//! Inputs: an actor in the arena with random bytes, and an arg0 whose bits are
//! each set with probability 1/3, so every mask of the C is hit alone, with
//! others, or not at all. Stats are biased so intelligence + currentInt sums
//! near zero (the `var_a3 < 0` comparison seeing equal sides) and negative
//! sums both occur. Weapon, shield and limb armour ids are zero or not, with
//! sign-bit values. The callees write back the actor fields the C re-reads.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80086FA8));

pub const classes = [_][:0]const u8{ "plain", "bit29", "single-switch", "multi-switch" };

const id_edges = [_]u16{ 0, 0, 1, 0x8000, 0xFFFF };

/// The actor the stubs write back into; set by prepare.
var actor: ?*v.vs_battle_actor2 = null;

pub const stubs = struct {
    pub fn func_800E685C(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) void {
        _ = a;
        _ = b;
        _ = c;
        const s = actor orelse return;
        if (ctx.value(u1) == 1) s.intelligence = ctx.value(u16);
        if (ctx.value(u1) == 1) s.weapon.blade.id = ctx.value(u16);
    }

    pub fn func_80086EA4(ctx: *zd.Ctx, p: anytype, a: anytype, b: anytype, c: anytype) void {
        _ = a;
        _ = b;
        _ = c;
        const s: *v.vs_battle_actor2 = @ptrCast(@alignCast(p.?));
        if (ctx.value(u1) == 1) s.intelligence = ctx.value(u16);
        if (ctx.value(u1) == 1) s.weapon.currentInt = ctx.value(i16);
        if (ctx.value(u1) == 1) s.weapon.currentStr = ctx.value(i16);
    }

    pub fn func_80086EF4(ctx: *zd.Ctx, p: anytype, a: anytype, b: anytype, c: anytype) void {
        _ = a;
        _ = b;
        _ = c;
        const s: *v.vs_battle_actor2 = @ptrCast(@alignCast(p.?));
        if (ctx.value(u1) == 1) s.intelligence = ctx.value(u16);
        if (ctx.value(u1) == 1) s.weapon.currentInt = ctx.value(i16);
        if (ctx.value(u1) == 1) s.limbs[0].armor.armor.id = ctx.value(u16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const a = ctx.alloc(v.vs_battle_actor2);
    actor = a;

    var m: u32 = 0;
    for (0..32) |b| {
        if (ctx.chance(3)) m |= @as(u32, 1) << @as(u5, @intCast(b));
    }

    // Sums of intelligence + currentInt near zero, and negative ones.
    if (ctx.chance(3)) {
        a.intelligence = ctx.range(u16, 0, 20);
        a.weapon.currentInt = ctx.range(i16, -20, 20);
    }

    // Wrap edges for the narrowing stores.
    a.weapon.currentStr = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });
    a.shield.currentStr = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });

    // Zero and nonzero ids, with the sign bit set sometimes.
    a.weapon.blade.id = ctx.edge(u16, &id_edges);
    a.shield.base.id = ctx.edge(u16, &id_edges);
    for (&a.limbs) |*limb| {
        limb.armor.armor.id = ctx.edge(u16, &id_edges);
    }

    const arg0: c_int = @bitCast(m);
    return .{ arg0, a };
}

pub fn classify(args: Args) usize {
    const x: u32 = @bitCast(args[0]);
    const lo = x & 0x01E00000;
    const hi = x & 0x1E000000;
    if ((x & 0x20000000) != 0) return 1;
    if ((lo != 0 and @popCount(lo) == 1) or (hi != 0 and @popCount(hi) == 1)) return 2;
    if (lo != 0 or hi != 0) return 3;
    return 0;
}
