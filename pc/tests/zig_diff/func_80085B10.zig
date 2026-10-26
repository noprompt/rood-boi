//! zig_diff spec: func_80085B10 -> func_80085B10.func_80085B10 (146C.c).
//! Inputs: an action 0-255 whose two hit prerequisites are drawn from the
//! switch's cases (0, 1, 3, 6, 7, 8, 9), so both the default loop and the
//! case 3 path run. The attacker is detached (source unk40 nonzero, so no
//! attacker, and no statCalc 2/25 with type 0) or attached to one of 16
//! actors that share four stats blocks. The affinity is 0 or not, the
//! weapon search runs with and without weaponDrawn bit 0 and a blade id,
//! and affinity values include ties and negatives. Hit entries have unk40
//! 0, 1..5, 6, 7 and -1 (the `< 6` edge), and targetActor 0..15. A flags bit
//! enables the redirect path, whose stub returns pad values 0, 17, 0..19
//! and any i16. The stubs write the fields the C reads back (hp, mp,
//! targetActor, the stats bit unk956_0, currentRange, the result header)
//! and return the redirect, hit and can-perform results both ways.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80085B10));

pub const classes = [_][:0]const u8{ "detached", "affinity", "weapon-search", "no-weapon" };

/// Views a C pointer, a native pointer, an optional one or a pointer to an
/// array as a `*T` (for an array, its first element).
fn asPtr(comptime T: type, p: anytype) *T {
    const q = if (@typeInfo(@TypeOf(p)) == .optional) p.? else p;
    const Q = @TypeOf(q);
    if (@typeInfo(Q).pointer.size == .one and @typeInfo(@typeInfo(Q).pointer.child) == .array) {
        return @ptrCast(@alignCast(&q[0]));
    }
    return @ptrCast(@alignCast(q));
}

pub const stubs = struct {
    pub fn func_800856F8(ctx: *zd.Ctx, p: anytype) void {
        const r = asPtr(v.D_800F19CC_t2, p);
        r.unk48 = ctx.value(u16);
        r.unk844.vx = ctx.value(i16);
    }

    pub fn func_80085718(ctx: *zd.Ctx, e: anytype) void {
        const h = asPtr(v._hitEntity_t, e);
        h.unk0.targetActor = ctx.value(u8) & 15; // indexes vs_battle_actors
        h.unk0.unk3 = ctx.value(u8);
        h.unk40 = if (ctx.value(u1) == 1) 0 else ctx.value(i32);
    }

    pub fn func_80085390(ctx: *zd.Ctx, spec: anytype, user: anytype, entry: anytype, arg3: anytype, hit: anytype) void {
        _ = spec;
        _ = user;
        _ = arg3;
        _ = hit;
        const e = asPtr(v._hitEntity_t, entry);
        e.unk0.hp = ctx.value(i16);
        e.unk0.targetActor = ctx.value(u8) & 15;
        if (ctx.value(u2) == 0) {
            // The effect may flip the target's stats bit that the C reads back.
            const target = v.g.vs_battle_actors()[e.unk0.targetActor].?;
            psx.setBits(psx.get(target.stats).?, "unk956_0", ctx.value(u1));
        }
    }

    pub fn func_80085008(ctx: *zd.Ctx, e: anytype) void {
        asPtr(v._hitEntity_t, e).unk0.mp = ctx.value(i16);
    }

    pub fn func_800A1AF8(ctx: *zd.Ctx, actor: anytype, mode: anytype, out: anytype, flag: anytype) void {
        _ = actor;
        _ = mode;
        _ = flag;
        const o = asPtr(v.SVECTOR, out);
        o.vx = ctx.value(i16);
        o.vy = ctx.value(i16);
        o.vz = ctx.value(i16);
    }

    pub fn func_80077F14(ctx: *zd.Ctx, actor: anytype, limb: anytype, out: anytype) void {
        _ = actor;
        _ = limb;
        const o = asPtr(v.SVECTOR, out);
        o.vx = ctx.value(i16);
        o.vy = ctx.value(i16);
        o.vz = ctx.value(i16);
    }

    pub fn func_800E6C34(ctx: *zd.Ctx, origin: anytype, position: anytype, impact: anytype, target: anytype) c_int {
        _ = origin;
        _ = position;
        _ = target;
        const o = asPtr(v.SVECTOR, impact);
        o.vx = ctx.value(i16);
        o.vy = ctx.value(i16);
        o.vz = ctx.value(i16);
        o.pad = switch (ctx.value(u2)) {
            0 => 0,
            1 => 17,
            2 => @as(i16, @intCast(ctx.value(u8) % 20)),
            else => ctx.value(i16),
        };
        return @intCast(ctx.value(u1));
    }

    pub fn func_80085A34(ctx: *zd.Ctx, p: anytype) void {
        const r = asPtr(v.func_80085A34_t, p);
        r.unk4 = ctx.value(i32);
    }

    pub fn func_800859B4(ctx: *zd.Ctx, action: anytype, attacker: anytype, flag: anytype) void {
        _ = action;
        _ = flag;
        const a = asPtr(v.vs_battle_actor2, attacker);
        psx.setBits(a, "currentRange", ctx.value(u8));
    }

    pub fn _doesAttackHit(ctx: *zd.Ctx, spec: anytype, attacker: anytype, target: anytype, hit: anytype, arg3: anytype) c_int {
        _ = spec;
        _ = attacker;
        _ = target;
        _ = hit;
        _ = arg3;
        return @intCast(ctx.value(u1));
    }

    pub fn _canPerformAttack(ctx: *zd.Ctx, spec: anytype, entry: anytype, hit: anytype) c_int {
        _ = spec;
        _ = entry;
        _ = hit;
        return @intCast(ctx.value(u1));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    // Four stats blocks shared by the sixteen actors.
    var stats: [4]*v.vs_battle_actor2 = undefined;
    for (&stats) |*slot| {
        const s = ctx.alloc(v.vs_battle_actor2);
        s.unk957 = ctx.range(u8, 0, 15); // indexes vs_battle_actors
        psx.setBits(s, "unk956_0", ctx.int(u1));
        s.weapon.blade.id = ctx.pick(u16, &.{ 0, 1, 0xFFFF, 0x8000 });
        for (&s.weapon.classAffinityCurrent.affinity[0]) |*a| {
            a.* = ctx.pick(i16, &.{ 0, 1, -1, 5, 32767, -32768 });
        }
        slot.* = s;
    }

    // The actor table: all sixteen slots are live actors with stats.
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        const a = ctx.alloc(v.vs_battle_actor);
        psx.put(&a.stats, stats[i & 3]);
        a.weaponDrawn = ctx.pick(i32, &.{ 0, 1, 3, -1, -2147483647, 0x40000000 });
        a.unk27 = ctx.pick(u8, &.{ 0x80, 0x80, 0, 0x81 });
        table[i] = a;
    }

    // D_800F19CC: a valid block whose unk0 the C tests.
    const cur = ctx.alloc(v.D_800F19CC_t);
    cur.unk0 = if (ctx.chance(2)) 0 else ctx.pick(u32, &.{ 1, 0x8000_0000 });
    v.g.D_800F19CC().* = cur;

    const result = ctx.alloc(v.D_800F19CC_t2);
    const source = ctx.alloc(v.D_800F19CC_t2);

    const action: c_int = ctx.range(c_int, 0, 255);
    const spec = &v.g.actions()[@as(usize, @intCast(action))];
    for (0..2) |h| {
        psx.setBits(&spec.hitParams[h], "prerequisiteFunction", ctx.pick(u6, &.{ 0, 3, 6, 7, 8, 1, 9 }));
    }
    psx.setBits(&spec.hitParams[0], "affinity", ctx.pick(u3, &.{ 0, 0, 1, 3, 7 }));

    const detached = ctx.chance(4); // source unk40 nonzero: no attacker
    const sc = ctx.pick(u6, &.{ 2, 25, 0, 1, 24 });
    var ty = ctx.pick(u2, &.{ 0, 0, 1, 3 });
    // A null attacker must not reach attacker->weapon through type 0.
    if (detached and (sc == 2 or sc == 25) and ty == 0) ty = 1;
    psx.setBits(&spec.hitParams[0], "statCalculator", sc);
    psx.setBits(&spec.hitParams[0], "type", ty);
    psx.setBits(spec, "flagsD_6", ctx.int(u1)); // flags_0 bit 14: the redirect path

    source.unk4.unk40 = if (detached) ctx.pick(i32, &.{ 1, -1, 6, 5 }) else 0;
    source.unk4.unk0.targetActor = ctx.range(u8, 0, 15);
    source.unk4.unk0.targetLimb = ctx.int(i8);
    source.unk4A = ctx.range(u16, 0, 30);
    source.unk844.vx = ctx.int(i16);
    for (&source.unk4C) |*e| {
        e.unk40 = ctx.pick(i32, &.{ 0, 0, 1, 5, 6, 7, -1 });
        e.unk0.targetActor = ctx.range(u8, 0, 15);
    }

    const arg3 = ctx.pick(c_int, &.{ 0, 1, -1, 2 });
    return .{ action, result, source, arg3 };
}

pub fn classify(args: Args) usize {
    const source = args[2].?;
    if (source.unk4.unk40 != 0) return 0;
    const spec = &v.g.actions()[@as(usize, @intCast(args[0]))];
    if (psx.getBits(&spec.hitParams[0], "affinity") != 0) return 1;
    const actor = v.g.vs_battle_actors()[source.unk4.unk0.targetActor].?;
    const attacker = psx.get(actor.stats).?;
    const searcher = v.g.vs_battle_actors()[attacker.unk957].?;
    if ((searcher.weaponDrawn & 1) != 0 and attacker.weapon.blade.id != 0) return 2;
    return 3;
}
