//! zig_diff spec: func_800CFEF0 -> func_800CFEF0.func_800CFEF0 (5BF94.c).
//! Inputs: a D_800F53B8_t in the arena with room for all 256 effect states
//! (the loop writes arg0->unk1C[i] up to i = 255, which runs past unk1C into
//! unkD1C, as the C does), a D_800F569C_t whose block9 count is 0, 1, 15, 16,
//! 17 or 255, and a block10 of 256 definitions with random flags, so every
//! switch case and the `& 4` / `& 0x200` tests occur. The attachment and
//! target sources (unkD1C.unk24 or unkC) are an actor (== 4) half the time.
//! The callees write a random matrix into their destination.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CFEF0));

pub const classes = [_][:0]const u8{ "empty", "over-16", "actor-src", "vector-src" };

// The last state starts at 0x1C + 255 * 0xD0 and ends at 0xD11C: the block
// must hold all of it, and the source fields (up to 0xD4C) too.
const arg0_bytes = 0xD120;
const count_edges = [_]u8{ 0, 1, 15, 16, 17, 255 };

fn fillMatrix(ctx: *zd.Ctx, m: *v.MATRIX) void {
    for (0..3) |r| {
        for (0..3) |c| {
            m.m[r][c] = ctx.value(i16);
        }
    }
    for (0..3) |k| {
        m.t[k] = ctx.value(i32);
    }
}

pub const stubs = struct {
    // Rewrites the facing matrix the C passes in.
    pub fn func_800CFE7C(ctx: *zd.Ctx, facing: anytype) void {
        const m: *v.MATRIX = @ptrCast(@alignCast(facing));
        fillMatrix(ctx, m);
    }

    // Writes the attachment matrix from the source vector; the source is only read.
    pub fn func_800CFE98(ctx: *zd.Ctx, src: anytype, dst: anytype) void {
        _ = src;
        const m: *v.MATRIX = @ptrCast(@alignCast(dst));
        fillMatrix(ctx, m);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    // The arg block comes first so it has room for every effect state.
    const arg0: *v.D_800F53B8_t = @ptrCast(@alignCast(ctx.allocBytes(arg0_bytes, 16)));
    const defs: *[256]v.func_800D0B30_t = @ptrCast(@alignCast(ctx.allocBytes(@sizeOf([256]v.func_800D0B30_t), 16)));
    const block9: *v.pFileBlock9 = ctx.alloc(v.pFileBlock9);
    const d: *v.D_800F569C_t = ctx.alloc(v.D_800F569C_t);

    block9.unk15 = ctx.pick(u8, &count_edges);
    psx.put(&d.block9Data, block9);
    psx.put(&d.block10Data, defs);
    v.g.D_800F569C().* = d;

    // Source selectors for the 0x10/8 and 0x800/0x400 switch cases.
    arg0.unkD1C.unk24.unk0 = if (ctx.chance(2)) 4 else ctx.int(u16);
    arg0.unkD1C.unkC.unk0 = if (ctx.chance(2)) 4 else ctx.int(u16);

    return .{arg0};
}

pub fn classify(args: Args) usize {
    const arg0 = args[0].?;
    const d = v.g.D_800F569C().*.?;
    const count = psx.get(d.block9Data).?.unk15;
    if (count == 0) return 0;
    if (count >= 16) return 1;
    if (arg0.unkD1C.unk24.unk0 == 4) return 2;
    return 3;
}
