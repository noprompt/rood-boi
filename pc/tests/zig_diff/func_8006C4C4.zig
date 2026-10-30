//! zig_diff spec: func_8006C4C4 -> func_8006C4C4.func_8006C4C4 (146C.c).
//! Inputs: a D_800F19CC_t request in the arena (its unk0 picks the
//! unk854 slot, so all four slots occur), and a _hitEntity_t whose unk40 is
//! 0 (hit path: a hit threshold from func_800A152C) or nonzero with and
//! without the sign bit (copy path: the entity's unk0 copied into the
//! request). arg0 and targetLimb take 0, +/-1, the i32 extremes and limb
//! values. The request is copied out of the stack by the stub of
//! func_800CF3F8, so every field the C writes is compared.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006C4C4));

pub const classes = [_][:0]const u8{ "entity-zero-unk40", "entity-nonzero-unk40" };

pub const stubs = struct {
    /// Returns any 32-bit value: the C stores it in a u8 (hitThreshold), so the
    /// truncation is compared.
    pub fn func_800A152C(ctx: *zd.Ctx, actor_id: anytype, a: anytype, b: anytype) c_int {
        _ = actor_id;
        _ = a;
        _ = b;
        return ctx.value(c_int);
    }

    /// Copies the request out (the C's stack object, its real size) into an
    /// arena block so its contents are compared, then returns any value
    /// (the C ignores it).
    pub fn func_800CF3F8(ctx: *zd.Ctx, req: anytype, mode: anytype) c_int {
        _ = mode;
        const n = @sizeOf(v.func_8006C4C4_t);
        const src: [*]const u8 = @ptrCast(req);
        const dst = ctx.allocBytes(n, 16);
        @memcpy(dst[0..n], src[0..n]);
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    // The global request pointer D_800F19CC: an arena object (its unk0 is
    // random, so unk0 & 3 picks every slot of unk854).
    const req = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = req;

    const hit = ctx.alloc(v._hitEntity_t);
    if (ctx.chance(2)) {
        hit.unk40 = 0;
    } else {
        hit.unk40 = ctx.edge(i32, &.{ 1, -1, 0x7fff_ffff, -0x8000_0000, 256 });
    }

    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7fff_ffff, -0x8000_0000 });
    const limb = ctx.pick(c_int, &.{ 0, 1, -1, 5, 6, 0x7fff_ffff, -0x8000_0000 });
    return .{ arg0, hit, limb };
}

pub fn classify(args: Args) usize {
    return if (args[1].?.unk40 == 0) 0 else 1;
}
