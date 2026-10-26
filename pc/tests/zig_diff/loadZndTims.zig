//! zig_diff spec: _loadZndTims -> load_znd_tims.loadZndTims (146C.c).
//! Inputs: a four-entry pointer table in the arena (the first size positive,
//! the others any sign or zero, so the `> 0` test takes both sides), a block
//! 0 holding 0, 1, 2, 3 or -1 tims with sizes 0..32 bytes, and an all-zero
//! payload so a port that reads a shifted word still reads a size of 0. The
//! tim parser is a stub writing a RECT at a fixed arena address: x exactly
//! 767, 768 and 769 often (the compare is compiled as `x > 767`, so 767 is
//! its equality case), above and below 768 too, and the full range; y around
//! the CLUT lines 224..227 (and 228 for the `< 4` equality, and below 224 for
//! the unsigned wrap), h from -2 to 6 (empty loops included), w 0..4, and a
//! NULL or arena paddr.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").loadZndTims));

pub const classes = [_][:0]const u8{ "no-tims", "one-tim", "several-tims" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const w: [*]i32 = @ptrCast(@alignCast(&zd.zdiff_arena[0]));
    // Payload words stay zero: a port that reads a shifted word reads a size of 0.
    @memset(zd.zdiff_arena[0..4096], 0);
    // Table: entry 0 is the size of block 0 and must be positive (it is dereferenced).
    w[0] = ctx.range(i32, 1, 40);
    w[1] = ctx.range(i32, -8, 40);
    w[2] = ctx.range(i32, -8, 40);
    w[3] = ctx.range(i32, -8, 40);
    // Block 0: numTims, then per tim a size word followed by size/4 payload words.
    const num = ctx.edge(i32, &.{ 0, 1, 2, 3, -1 });
    w[4] = num;
    var p: usize = 5;
    var i: i32 = 0;
    while (i < num) : (i += 1) {
        const sz: i32 = ctx.range(i32, 0, 8) * 4;
        w[p] = sz;
        p += 1 + @as(usize, @intCast(sz >> 2));
    }
    return .{@ptrCast(&zd.zdiff_arena[0])};
}

pub fn classify(args: Args) usize {
    const w: [*]const i32 = @ptrCast(@alignCast(args[0].?));
    const num = w[4];
    if (num <= 0) return 0;
    if (num == 1) return 1;
    return 2;
}

fn rectAt(i: usize) *v.RECT {
    return @ptrCast(@alignCast(&zd.zdiff_arena[1024 + 16 * i]));
}

pub const stubs = struct {
    pub fn vs_battle_parseTim(ctx: *zd.Ctx, data: anytype, tim: anytype) void {
        _ = data;
        const t: *v.TIM_IMAGE = @ptrCast(@alignCast(tim));
        const r = rectAt(ctx.value(u8) & 3);
        const xk = ctx.value(u8);
        // 767 and 768 are drawn often: the C's `x >= 768` is compiled as `x > 767`,
        // so 767 is the equality case and 768 the first value on the other side.
        r.x = if (xk < 40)
            768
        else if (xk < 80)
            767
        else if (xk < 120)
            768 + @as(i16, @intCast(ctx.value(u8) & 63))
        else if (xk < 160)
            @as(i16, ctx.value(u8))
        else
            ctx.value(i16);
        const yk = ctx.value(u8);
        r.y = if (yk < 160) 220 + @as(i16, @intCast(yk % 12)) else ctx.value(i16);
        r.h = @as(i16, @intCast(ctx.value(u8) % 9)) - 2;
        r.w = @as(i16, @intCast(ctx.value(u8) % 5));
        t.mode = ctx.value(u32);
        t.crect = null;
        t.caddr = null;
        t.prect = r;
        t.paddr = if (ctx.value(u8) < 56)
            null
        else
            @as(*u32, @ptrCast(@alignCast(&zd.zdiff_arena[4096])));
    }
};
