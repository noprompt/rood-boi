//! zig_diff spec: func_8008EFCC -> func_8008EFCC.func_8008EFCC (146C.c).
//! Inputs: the room's section10 pointer (null in some runs) pointing at an
//! arena block whose two CdFile entries (at u16 offsets 0x20 and 0x42, so
//! byte offsets 0x40 and 0x84) carry sizes from four families: edge values
//! (negative, near INT_MAX, 0x800 multiples), 0x800-aligned sizes, sizes in
//! 0..0x6000 with random low bits, and huge sizes. The arg is truncated into
//! D_800F1DC8 and passed on. Callee stubs: func_8007DFF0 can rewrite the
//! two sizes and returns zero or nonzero; vs_main_allocHeapR returns null for
//! large sizes or at random; allocateCdQueueSlot returns null or a slot;
//! cdEnqueue may rewrite the slot's state.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008EFCC));

pub const classes = [_][:0]const u8{ "no-section", "huge-size", "aligned-sizes", "rounded-sizes" };

var cls: usize = 0;

fn sizeOf(ctx: *zd.Ctx) i32 {
    return switch (ctx.range(u8, 0, 9)) {
        0 => ctx.edge(i32, &.{ -1, -2048, -0x80000000, 0x7FFFF000, 0x8000, 0x7FF, 0x800 }),
        1, 2 => ctx.range(i32, 0, 0x6000) & ~@as(i32, 0x7FF),
        else => ctx.range(i32, 0, 0x6000),
    };
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const base: [*]u8 = ctx.allocBytes(0x100, 16);
    const sec: *u16 = @ptrCast(@alignCast(base));
    const cd2: *v.vs_main_CdFile = @ptrCast(@alignCast(base + 0x40));
    const cd3: *v.vs_main_CdFile = @ptrCast(@alignCast(base + 0x84));
    cd2.size = sizeOf(ctx);
    cd3.size = sizeOf(ctx);
    const p: ?*u16 = if (ctx.chance(6)) null else sec;
    psx.put(&v.g.vs_battle_roomData().section10, p);
    if (p == null) {
        cls = 0;
    } else if (cd2.size < 0 or cd3.size < 0 or cd2.size > 0x8000 or cd3.size > 0x8000) {
        cls = 1;
    } else if ((cd2.size & 0x7FF) == 0 and (cd3.size & 0x7FF) == 0) {
        cls = 2;
    } else {
        cls = 3;
    }
    return .{ctx.pick(c_int, &.{ 0, 1, -1, 0x100, 0x7FFFFFFF })};
}

pub fn classify(args: Args) usize {
    _ = args;
    return cls;
}

pub const stubs = struct {
    pub fn func_8007DFF0(ctx: *zd.Ctx, a: anytype, b: anytype, n: anytype) c_int {
        _ = a;
        _ = b;
        _ = n;
        // The callee may rewrite the two CdFile sizes the C reads back.
        const sec = psx.get(v.g.vs_battle_roomData().section10).?;
        const base: [*]u8 = @ptrCast(sec);
        if (ctx.value(u1) == 1) psx.byteAt(i32, base, 0x44).* = @as(i32, ctx.value(u16));
        if (ctx.value(u1) == 1) psx.byteAt(i32, base, 0x88).* = @as(i32, ctx.value(u16));
        if (ctx.value(u2) == 0) return 0;
        return @as(c_int, ctx.value(u16) | 1);
    }

    pub fn vs_main_allocHeapR(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        if (size > 0x8000 or ctx.value(u2) == 0) return null;
        const p: *anyopaque = @ptrCast(ctx.allocBytes(@as(usize, size), 16));
        return p;
    }

    pub fn vs_main_allocateCdQueueSlot(ctx: *zd.Ctx, cd: anytype) ?*v.vs_main_CdQueueSlot {
        _ = cd;
        if (ctx.value(u2) == 0) return null;
        return ctx.alloc(v.vs_main_CdQueueSlot);
    }

    pub fn vs_main_cdEnqueue(ctx: *zd.Ctx, slot: anytype, vram: anytype) void {
        _ = vram;
        if (@intFromPtr(slot) != 0 and ctx.value(u1) == 1) {
            const s: *v.vs_main_CdQueueSlot = @ptrCast(@alignCast(slot));
            s.state = ctx.value(i16);
        }
    }
};
