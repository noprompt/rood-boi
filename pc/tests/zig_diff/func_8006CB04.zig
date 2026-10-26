//! zig_diff spec: func_8006CB04 -> func_8006CB04.func_8006CB04 (146C.c).
//! Inputs: arg0 either in 0..15 (the entry loop, with entries whose targetActor
//! matches arg0 sometimes, unk40 zero or not, unk3 from 0..6 and 255) or an
//! edge/random value at or above 16 (16 twice in the pool, the 0x10/0x20/0x80
//! prongs, other masks). The D_800E8194 table gets zero and nonzero entries so
//! both halves of the case-3/4 test run. arg1 is null sometimes. The stubs write
//! the state the real callees can change: the entry's unk40 and the SVECTOR and
//! func_8006CE70_t the C passes them.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006CB04));

pub const classes = [_][:0]const u8{ "arg0-at-least-16", "low-no-match", "low-matched" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0: c_int = if (ctx.chance(2))
        ctx.range(c_int, 0, 15)
    else
        ctx.pick(c_int, &.{ 16, 16, 0x10, 0x20, 0x80, 0x90, 0x100, 0x1F0, 0x200, -1, -16, 0x7fff_ffff, -0x8000_0000 });
    const arg1: ?*v.func_8006CE70_t = if (ctx.chance(6)) null else ctx.alloc(v.func_8006CE70_t);

    const d = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = d;
    d.unk0 = ctx.int(u32);
    const t = &d.unk854[d.unk0 & 3];
    t.unk4A = ctx.range(u16, 0, 30);
    t.actionIndex = ctx.range(u16, 0, 255);

    const tgt: u8 = if (arg0 >= 0 and arg0 < 256) @intCast(arg0) else ctx.int(u8);
    for (&t.unk4C) |*e| {
        if (ctx.chance(2)) e.unk0.targetActor = tgt;
        e.unk0.unk3 = ctx.edge(u8, &.{ 0, 1, 2, 3, 4, 5, 6, 0xFF });
        e.unk40 = if (ctx.chance(4)) ctx.pick(i32, &.{ 1, -1 }) else 0;
    }

    // Both zero and nonzero entries: the case-3/4 test sees each.
    const tbl = v.g.D_800E8194();
    for (0..32) |k| tbl[k] = if (ctx.chance(2)) 0 else ctx.range(u8, 1, 255);

    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    const arg0 = args[0];
    if (arg0 >= 16) return 0;
    const d = v.g.D_800F19CC().*.?;
    const t = &d.unk854[d.unk0 & 3];
    var i: usize = 0;
    while (i < t.unk4A) : (i += 1) {
        const e = &t.unk4C[i];
        if (@as(i32, e.unk0.targetActor) == arg0 and e.unk40 == 0) return 2;
    }
    return 1;
}

pub const stubs = struct {
    pub fn _applyBattleAbilityEffect(ctx: *zd.Ctx, p: anytype) void {
        const e: *v._hitEntity_t = @ptrCast(@alignCast(p.?));
        if (ctx.value(u1) == 1) e.unk40 = ctx.value(i32);
    }

    pub fn func_80093B04(ctx: *zd.Ctx, p: anytype) void {
        const q = p orelse return;
        const a: *v.func_8006CE70_t = @ptrCast(@alignCast(q));
        a.unk4 = ctx.value(i16);
        if (ctx.value(u1) == 1) a.unk0 = ctx.value(i32);
    }

    pub fn func_8009EA14(ctx: *zd.Ctx, a: anytype, b: anytype) void {
        _ = a;
        const s: *v.SVECTOR = @ptrCast(@alignCast(b));
        s.vx = ctx.value(i16);
    }
};
