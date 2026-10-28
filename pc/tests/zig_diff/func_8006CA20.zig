//! zig_diff spec: func_8006CA20 -> func_8006CA20.func_8006CA20 (146C.c).
//! Inputs: a fresh D_800F19CC_t in the arena installed as the global, with
//! arg0 mostly in 0..15 and sometimes 0, 16, -1, 255 or the int extremes. The
//! selected slot (unk0 & 3) targets arg0 most of the time, sometimes 0xFF (so
//! arg0 == -1 meets an unsigned 255 read), and its unk40 is zero or not (both
//! signs). unk3 covers the switch cases 0-6 and 255. The callees are recording
//! stubs that write their SVECTOR, the global, and the hit entity, and return
//! nothing.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006CA20));

pub const classes = [_][:0]const u8{
    "out-of-range",
    "not-target",
    "hit-flag-set",
    "case-0-1",
    "case-2-4",
    "case-5-actor0",
    "case-5-other",
    "other-kind",
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = d;
    d.unk0 = ctx.int(u32);
    const t = &d.unk854[d.unk0 & 3];

    const arg0: c_int = if (ctx.chance(4))
        ctx.pick(c_int, &.{ 16, -1, 255, std.math.maxInt(c_int), std.math.minInt(c_int) })
    else if (ctx.chance(3))
        0
    else
        ctx.range(c_int, 0, 15);

    if (ctx.chance(8)) {
        t.unk4.unk0.targetActor = ctx.int(u8);
    } else if (ctx.chance(6)) {
        t.unk4.unk0.targetActor = 0xFF;
    } else {
        t.unk4.unk0.targetActor = psx.conv(u8, arg0);
    }

    t.unk4.unk40 = ctx.pick(i32, &.{ 0, 0, 1, -1, std.math.minInt(i32) });

    if (ctx.chance(10)) {
        t.unk4.unk0.unk3 = ctx.int(u8);
    } else {
        t.unk4.unk0.unk3 = ctx.edge(u8, &.{ 0, 1, 2, 3, 4, 5, 6, 0xFF });
    }

    const arg1: ?*v.func_8006CE70_t = if (ctx.chance(2)) null else ctx.alloc(v.func_8006CE70_t);
    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    const arg0 = args[0];
    if (arg0 < 0 or arg0 >= 16) return 0;
    const d = v.g.D_800F19CC().*.?;
    const t = &d.unk854[d.unk0 & 3];
    if (@as(c_int, t.unk4.unk0.targetActor) != arg0) return 1;
    if (t.unk4.unk40 != 0) return 2;
    return switch (t.unk4.unk0.unk3) {
        0, 1 => 3,
        2, 3, 4 => 4,
        5 => if (arg0 == 0) 5 else 6,
        else => 7,
    };
}

pub const stubs = struct {
    pub fn func_8009EA14(ctx: *zd.Ctx, id: anytype, sv: anytype) void {
        _ = id;
        const p: *v.SVECTOR = @ptrCast(@alignCast(sv));
        if (ctx.value(u1) == 1) p.vx = ctx.value(i16);
        if (ctx.value(u1) == 1) p.vy = ctx.value(i16);
        if (ctx.value(u1) == 1) p.vz = ctx.value(i16);
        if (ctx.value(u1) == 1) v.g.D_800F19CC().*.?.unk2C0C = ctx.value(i16);
    }

    pub fn func_8009E070(ctx: *zd.Ctx, a: anytype, b: anytype, n: anytype) void {
        _ = a;
        _ = b;
        _ = n;
        v.g.D_800F19CC().*.?.unk2C00 = ctx.value(u16);
    }

    pub fn _applyBattleAbilityEffect(ctx: *zd.Ctx, h: anytype) void {
        const e: *v._hitEntity_t = @ptrCast(@alignCast(h));
        if (ctx.value(u1) == 1) e.unk0.hp = ctx.value(i16);
        if (ctx.value(u1) == 1) e.unk40 = ctx.value(i32);
    }
};
