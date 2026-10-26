//! zig_diff spec: func_800D2A38 -> func_800D2A38.func_800D2A38 (5BF94.c).
//! Inputs: an arena func_800FA098_arg1 whose flags carry the 0x40000 bit or not
//! (random sign bit either way), with edge values in unk2C (i16, sign-extended
//! into unk34 on the copy path) and in unk34/unk98 (so unk34 * 4096 wraps).
//! ApplyRotMatrix is a recording stub that overwrites its output VECTOR with
//! stub values, which the C reads back for the three stores into arg1.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D2A38));

pub const classes = [_][:0]const u8{ "rotate", "copy" };

fn edge32(ctx: *zd.Ctx) i32 {
    return ctx.pick(i32, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000, 0x0008_0000, 0x0007_FFFF, 0x0010_0000 });
}

fn edge16(ctx: *zd.Ctx) i16 {
    return ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 255, -256 });
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.alloc(v.func_800FA098_arg1);
    const arg1 = ctx.alloc(v.func_800D2904_t);

    // The rotate bit on about half the runs; the other flag bits stay random,
    // so the sign bit is set and clear on both paths.
    if (ctx.chance(2)) {
        arg0.flags |= 0x40000;
    } else {
        arg0.flags &= ~@as(u32, 0x40000);
    }

    arg0.unk2C.vx = edge16(ctx);
    arg0.unk2C.vy = edge16(ctx);
    arg0.unk2C.vz = edge16(ctx);

    arg0.unk34.vx = edge32(ctx);
    arg0.unk34.vy = edge32(ctx);
    arg0.unk34.vz = edge32(ctx);

    arg0.unk98.vx = edge32(ctx);
    arg0.unk98.vy = edge32(ctx);
    arg0.unk98.vz = edge32(ctx);

    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    return if ((args[0].?.flags & 0x40000) != 0) 0 else 1;
}

pub const stubs = struct {
    // The real callee rotates v0 into v1: the C reads v1 back after the call.
    pub fn ApplyRotMatrix(ctx: *zd.Ctx, v0: anytype, v1: anytype) [*c]v.VECTOR {
        _ = v0;
        const out: *v.VECTOR = @ptrCast(@alignCast(v1));
        out.vx = ctx.value(i32);
        out.vy = ctx.value(i32);
        out.vz = ctx.value(i32);
        return null;
    }
};
