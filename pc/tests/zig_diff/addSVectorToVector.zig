//! zig_diff spec: _addSVectorToVector -> add_svector_to_vector.addSVectorToVector (5BF94.c).
//! Inputs: an SVECTOR, a source VECTOR and an output VECTOR, all in the arena, with
//! random fields biased toward wrap-around edges (extreme i16 and i32 values, so sums
//! overflow and svec->vy is negative about half the time). The output may alias the
//! SVECTOR or the source VECTOR, and the source may alias the SVECTOR: the C reads
//! svec->vy before its first store, so an alias exposes any read moved past a store.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").addSVectorToVector));

pub const classes = [_][:0]const u8{ "distinct", "out-is-svec", "out-is-vec", "vec-is-svec" };

pub fn prepare(ctx: *zd.Ctx) Args {
    // Three 16-byte blocks: the SVECTOR (8 bytes) lives at the start of blk_s.
    const blk_s = ctx.alloc(v.VECTOR);
    const blk_v = ctx.alloc(v.VECTOR);
    const blk_o = ctx.alloc(v.VECTOR);

    const svec: *v.SVECTOR = @ptrCast(blk_s);
    svec.vx = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });
    svec.vy = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });
    svec.vz = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });

    blk_v.vx = ctx.pick(i32, &.{ 0, -1, 0x7fffffff, -0x80000000 });
    blk_v.vy = ctx.pick(i32, &.{ 0, -1, 0x7fffffff, -0x80000000 });
    blk_v.vz = ctx.pick(i32, &.{ 0, -1, 0x7fffffff, -0x80000000 });

    const out_sel = ctx.range(u8, 0, 9);
    const out: *v.VECTOR = if (out_sel < 6) blk_o else if (out_sel < 8) blk_s else blk_v;
    const vec: *v.VECTOR = if (ctx.chance(5)) blk_s else blk_v;

    return .{ svec, vec, out };
}

pub fn classify(args: Args) usize {
    const s: usize = @intFromPtr(args[0].?);
    const src: usize = @intFromPtr(args[1].?);
    const o: usize = @intFromPtr(args[2].?);
    if (o == s) return 1;
    if (o == src) return 2;
    if (src == s) return 3;
    return 0;
}
