//! zig_diff spec: func_800C8778 -> func_800C8778.func_800C8778 (5BF94.c).
//! Inputs: the gim pointer D_800EB9BC (null in some runs), three gim_t objects
//! in one arena block with room for the overflow the C writes (imageTable past
//! 254 runs into the next object), a CD queue slot in state 4 or not, and a
//! u16 data buffer. Its headers (width | tiles << 8) pick 0-3 images, with
//! data[3] at 0, 1, 2 and sign-bit values, and every unk0_6 mode 0-7 (4-7 do
//! nothing). Headers stay small so every read stays inside the buffer. The
//! frame-count byte covers 0, 16, 17, 18 and 255, and the per-object unk0_0 bits
//! are random, so the callee's rewrite is observable.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800C8778));

pub const classes = [_][:0]const u8{
    "null-gim",
    "idle",
    "cd-not-ready",
    "single-image",
    "double-image",
    "triple-image",
    "free-heap",
    "clear-flags",
};

var cls_now: usize = 0;

/// A block header: low byte width, high byte tiles. Kept small (product at most
/// 404) unless the low byte is large, in which case tiles is 0 or 1.
fn header(ctx: *zd.Ctx) u16 {
    const w = ctx.edge(u8, &.{ 0, 1, 2, 3, 4, 8, 16, 17, 18, 20, 127, 128, 200, 255 });
    const j: u8 = if (w >= 32)
        ctx.edge(u8, &.{ 0, 1 })
    else
        ctx.edge(u8, &.{ 0, 1, 2, 3, 4, 8, 16, 17, 18, 20 });
    return @as(u16, w) | (@as(u16, j) << 8);
}

/// The count a block header advances the C's index by: (h & 0xFF) * (h >> 8) + 4.
fn blockCount(h: u16) usize {
    return @as(usize, h & 0xFF) * @as(usize, h >> 8) + 4;
}

/// Fills the data buffer for a ready CD slot and returns the class.
fn fillImages(ctx: *zd.Ctx, d: [*]u16) usize {
    const d3s = [_]u16{ 0, 0, 1, 2, 2, 3, 0x8000, 0xFFFF, 0x8002 };
    const d3 = ctx.edge(u16, &d3s);
    d[0] = header(ctx);
    const i_lo = ctx.edge(u8, &.{ 0, 1, 2, 16, 17, 18, 33, 34, 100, 255 });
    d[1] = (@as(u16, ctx.int(u8)) << 8) | @as(u16, i_lo);
    d[2] = ctx.edge(u16, &.{ 0, 1, 2, 2, 3, 0x8000, 0xFFFF });
    d[3] = d3;
    if (d3 == 0) return 3;
    const c1 = blockCount(d[0]);
    d[c1] = header(ctx);
    const c2 = c1 + blockCount(d[c1]);
    d[c1 + 2] = ctx.edge(u16, &.{ 0, 1, 2, 3, 0xFFFF });
    if (d3 != 2) return 4;
    d[c2] = header(ctx);
    d[c2 + 2] = ctx.edge(u16, &.{ 0, 1, 2, 3, 0xFFFF });
    return 5;
}

pub fn prepare(ctx: *zd.Ctx) Args {
    if (ctx.chance(12)) {
        v.g.D_800EB9BC().* = null;
        cls_now = 0;
        return .{};
    }
    const gim: *v.gim_t = @ptrCast(@alignCast(ctx.allocBytes(4096, 16)));
    const d: [*]u16 = @ptrCast(@alignCast(ctx.allocBytes(8192, 16)));
    const slot = ctx.alloc(v.vs_main_CdQueueSlot);
    slot.state = 4;
    psx.put(&gim.cdQueueSlot, slot);
    psx.put(&gim.data, @as(*u16, @ptrCast(d)));
    gim.unk2 = ctx.edge(u8, &.{ 0, 23, 24, 25, 40, 255 });
    v.g.D_800EB9BC().* = gim;

    const arr: [*]v.gim_t = @ptrCast(gim);
    for (0..3) |k| psx.setBits(&arr[k], "unk0_0", ctx.edge(u1, &.{ 0, 1 }));

    const mode = ctx.edge(u3, &.{ 0, 1, 1, 1, 1, 2, 2, 3, 3, 4, 5, 6, 7 });
    psx.setBits(gim, "unk0_6", mode);
    switch (mode) {
        1 => {
            if (ctx.chance(5)) {
                slot.state = ctx.edge(i16, &.{ 3, 5, 0, -4 });
                cls_now = 2;
            } else {
                slot.state = 4;
                cls_now = fillImages(ctx, d);
            }
        },
        2 => cls_now = 6,
        3 => cls_now = 7,
        else => cls_now = 1,
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return cls_now;
}

pub const stubs = struct {
    /// The callee clears or sets the unk0_0 flag of the object it was given.
    pub fn func_800CCA90(ctx: *zd.Ctx, arg0: anytype) void {
        const gim = v.g.D_800EB9BC().* orelse return;
        const arr: [*]v.gim_t = @ptrCast(gim);
        psx.setBits(&arr[@intCast(arg0)], "unk0_0", ctx.value(u1));
    }
};
