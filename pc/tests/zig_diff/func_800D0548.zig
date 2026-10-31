//! zig_diff spec: func_800D0548 -> func_800D0548.func_800D0548 (5BF94.c).
//! Inputs: arg0 with each flags&0x3000 selector (0, 0x1000, 0x2000 and the
//! unmatched 0x3000) and a random limit (edges included); arg1 with random
//! flags, bit 2 set or clear, and a frame that is EQUAL to the limit in a
//! third of the runs, below it, or negative (signed compare). The two
//! callees are recording stubs that rewrite the fields the C reads back
//! (arg1->flags, arg1->frame, arg0->limit) on some calls.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D0548));

pub const classes = [_][:0]const u8{
    "sel0-bit4-clear",
    "sel0-bit4-limit-lt-frame",
    "sel0-bit4-limit-ge-frame",
    "sel1000-bit4-clear",
    "sel1000-bit4-limit-lt-frame",
    "sel1000-bit4-limit-ge-frame",
    "sel2000-bit4-clear",
    "sel2000-bit4-limit-lt-frame",
    "sel2000-bit4-limit-ge-frame",
    "sel3000-bit4-clear",
    "sel3000-bit4-limit-lt-frame",
    "sel3000-bit4-limit-ge-frame",
};

/// Writes the fields the C reads back after a callee returns, on some calls.
fn touch(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) void {
    const a0: *v.func_800D0548_arg0 = @ptrCast(@alignCast(arg0));
    const a1: *v.func_800D0548_arg1 = @ptrCast(@alignCast(arg1));
    if (ctx.value(u1) == 1) a1.flags = ctx.value(u16);
    if (ctx.value(u1) == 1) a1.frame = ctx.value(i16);
    if (ctx.value(u1) == 1) a0.limit = ctx.value(u8);
}

pub const stubs = struct {
    pub fn func_800D01E4(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) void {
        touch(ctx, arg0, arg1);
    }
    pub fn func_800D037C(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) void {
        touch(ctx, arg0, arg1);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const a0 = ctx.alloc(v.func_800D0548_arg0);
    const a1 = ctx.alloc(v.func_800D0548_arg1);

    // The switch selector: 0, 0x1000, 0x2000, or 0x3000 (no case matches).
    const sel = ctx.edge(u16, &.{ 0x0000, 0x1000, 0x2000, 0x3000 });
    a0.flags = (ctx.int(u16) & 0xCFFF) | sel;
    a0.limit = ctx.pick(u8, &.{ 0, 1, 127, 128, 254, 255 });

    // Bit 2 of arg1->flags set or clear; the rest random (sign bit both ways).
    a1.flags = ctx.int(u16);
    if (ctx.chance(2)) {
        a1.flags |= 4;
    } else {
        a1.flags &= 0xFFFB;
    }

    // Equal to the limit a third of the time, else edges and random values.
    if (ctx.chance(3)) {
        a1.frame = a0.limit;
    } else {
        a1.frame = ctx.pick(i16, &.{ -1, 0, 1, 255, 256, -32768, 32767 });
    }

    return .{ a0, a1 };
}

pub fn classify(args: Args) usize {
    const a0 = args[0].?;
    const a1 = args[1].?;
    const sel: usize = switch (a0.flags & 0x3000) {
        0 => 0,
        0x1000 => 1,
        0x2000 => 2,
        else => 3,
    };
    const k: usize = if ((a1.flags & 4) == 0) 0 else if (a0.limit >= a1.frame) 2 else 1;
    return sel * 3 + k;
}
