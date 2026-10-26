//! zig_diff spec: func_800D0B30 -> func_800D0B30.func_800D0B30 (5BF94.c).
//! Inputs: a random func_800D0B30_t whose flag word is odd or even, with bit 15
//! set or clear (so the mask test sees both signs), table indices 0..32 with
//! both ends of the D_800F5330 room, an SVECTOR with edge components (the
//! wrapping `+=` stores), and a random output block. The lerps, the matrix
//! calls and func_800CFE7C are recording stubs that write their outputs with
//! ctx.value, so every value the C reads back comes from the harness.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D0B30));

pub const classes = [_][:0]const u8{ "odd-sign", "odd-nosign", "even" };

fn index(ctx: *zd.Ctx) u8 {
    if (ctx.chance(3)) return ctx.edge(u8, &.{ 0, 32 });
    return ctx.range(u8, 0, 32);
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const a = ctx.alloc(v.func_800D0B30_t);
    const s = ctx.alloc(v.SVECTOR);
    const out = ctx.alloc(v.func_800D0B30_t2);
    a.unk0 = ctx.pick(u16, &.{ 0, 1, 0x8000, 0x8001, 0xFFFE, 0xFFFF });
    a.unk4 = index(ctx);
    a.unk6 = index(ctx);
    a.unk7 = index(ctx);
    s.vx = ctx.pick(i16, &.{ 0, -1, 32767, -32768 });
    s.vy = ctx.pick(i16, &.{ 0, -1, 32767, -32768 });
    s.vz = ctx.pick(i16, &.{ 0, -1, 32767, -32768 });
    // The even path never touches arg1: a null there must not trap.
    const vec: ?*v.SVECTOR = if ((a.unk0 & 0x8001) == 0 and ctx.chance(3)) null else s;
    return .{ a, vec, out };
}

pub fn classify(args: Args) usize {
    const a = args[0].?;
    if ((a.unk0 & 1) == 0) return 2;
    return if ((a.unk0 & 0x8000) != 0) 0 else 1;
}

pub const stubs = struct {
    pub fn vs_battle_lerpSvector(ctx: *zd.Ctx, src: anytype, t: anytype, vec: anytype) void {
        _ = src;
        _ = t;
        const o: *v.SVECTOR = @ptrCast(@alignCast(vec));
        o.vx = ctx.value(i16);
        o.vy = ctx.value(i16);
        o.vz = ctx.value(i16);
    }

    pub fn vs_battle_lerpVector(ctx: *zd.Ctx, src: anytype, t: anytype, vec: anytype) void {
        _ = src;
        _ = t;
        const o: *v.VECTOR = @ptrCast(@alignCast(vec));
        o.vx = ctx.value(i32);
        o.vy = ctx.value(i32);
        o.vz = ctx.value(i32);
    }

    pub fn RotMatrix_gte(ctx: *zd.Ctx, r: anytype, m: anytype) [*c]v.MATRIX {
        _ = r;
        const mx: *v.MATRIX = @ptrCast(@alignCast(m));
        for (0..3) |i| {
            for (0..3) |j| mx.m[i][j] = ctx.value(i16);
        }
        mx.t[0] = ctx.value(i32);
        mx.t[1] = ctx.value(i32);
        mx.t[2] = ctx.value(i32);
        return null;
    }

    pub fn TransMatrix(ctx: *zd.Ctx, m: anytype, vec: anytype) [*c]v.MATRIX {
        _ = vec;
        const mx: *v.MATRIX = @ptrCast(@alignCast(m));
        mx.t[0] = ctx.value(i32);
        mx.t[1] = ctx.value(i32);
        mx.t[2] = ctx.value(i32);
        return null;
    }

    pub fn ScaleMatrix(ctx: *zd.Ctx, m: anytype, vec: anytype) [*c]v.MATRIX {
        _ = vec;
        const mx: *v.MATRIX = @ptrCast(@alignCast(m));
        mx.m[0][0] = ctx.value(i16);
        mx.m[1][1] = ctx.value(i16);
        mx.m[2][2] = ctx.value(i16);
        return null;
    }

    pub fn func_800CFE7C(ctx: *zd.Ctx, p: anytype) void {
        const o: *v.func_800CFE98_t = @ptrCast(@alignCast(p));
        o.unk0 = ctx.value(i32);
        o.unk4 = ctx.value(i32);
        o.unk8 = ctx.value(i32);
        o.unkC = ctx.value(i32);
        o.unk10 = ctx.value(i32);
        o.unk14.vx = ctx.value(i32);
        o.unk14.vy = ctx.value(i32);
        o.unk14.vz = ctx.value(i32);
    }
};
