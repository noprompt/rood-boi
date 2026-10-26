//! zig_diff spec: func_800CED60 -> func_800CED60.func_800CED60 (5BF94.c).
//! Inputs: a linear list of 0-4 D_800F53B8_t nodes off D_800F54B0 (no cycles).
//! Each node's unkD1C.unk3A takes case 2, case 3, case 4 or the default (-1, 0,
//! 1, 5), unk14_16 sits at its edges (0 and 0xFFFF, which wraps on ++), and a
//! case-4 node gets a renderer list of 0-3 nodes whose renderer returns 0
//! (func_800CF70C is called) or a value with or without the sign bit. The
//! curve block is present or null. The callees change what the C reads back
//! after them: func_800CF484 clears next and rewrites unk14_8, func_800CF614
//! rewrites unk14_8, func_800CF70C clears a renderer's next and a node's
//! renderer list, func_800D78F0 clears the curve block, and func_800D51D8
//! rewrites unk14_16 and returns 0 or any c_int.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CED60));

pub const classes = [_][:0]const u8{ "empty", "case-2-head", "case-3-head", "case-4-curve", "case-4-no-curve", "other-head" };

/// A pointer argument of any of the callee's pointer types, as a pointer to T.
fn as(comptime T: type, p: anytype) *T {
    if (@typeInfo(@TypeOf(p)) == .optional) return @ptrCast(@alignCast(p.?));
    return @ptrCast(@alignCast(p));
}

/// The renderer the C calls through `renderer`: its result is the low 32 bits
/// of the node's unk8, so prepare chooses zero, the sign bit or neither.
fn renderStub(self: ?*anyopaque, a: c_int, b: c_int) callconv(.c) c_int {
    _ = a;
    _ = b;
    const rn: *v.func_800D4910_t = @ptrCast(@alignCast(self.?));
    const bits: u32 = @truncate(@intFromPtr(rn.unk8));
    return @bitCast(bits);
}

pub const stubs = struct {
    pub fn func_800CF484(ctx: *zd.Ctx, arg0: anytype, node: anytype) void {
        _ = arg0;
        const n = as(v.D_800F53B8_t, node);
        if (ctx.value(u2) == 0) psx.put(&n.next, @as(?*v.D_800F53B8_t, null));
        if (ctx.value(u1) == 1) psx.setBits(n, "unk14_8", ctx.value(u3));
    }

    pub fn func_800CF614(ctx: *zd.Ctx, node: anytype) void {
        const n = as(v.D_800F53B8_t, node);
        if (ctx.value(u1) == 1) psx.setBits(n, "unk14_8", ctx.value(u3));
    }

    pub fn func_800CF70C(ctx: *zd.Ctx, node: anytype, r: anytype) void {
        const n = as(v.D_800F53B8_t, node);
        const rn = as(v.func_800D4910_t, r);
        if (ctx.value(u2) == 0) psx.put(&n.unkD1C.unk34, @as(?*v.func_800D4910_t, null));
        if (ctx.value(u2) == 0) rn.next = null;
    }

    pub fn func_800D51D8(ctx: *zd.Ctx, node: anytype) c_int {
        const n = as(v.D_800F53B8_t, node);
        if (ctx.value(u1) == 1) psx.setBits(n, "unk14_16", ctx.value(u16));
        if (ctx.value(u2) == 0) return 0;
        return ctx.value(c_int);
    }

    pub fn func_800D78F0(ctx: *zd.Ctx) void {
        const blk = v.g.D_800F569C().*.?;
        if (ctx.value(u2) == 0) psx.put(&blk.curveBlock, @as(?*v.pFileCurveBlock, null));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const block = ctx.alloc(v.D_800F569C_t);
    v.g.D_800F569C().* = block;
    const cb = ctx.alloc(v.pFileCurveBlock);
    psx.put(&block.curveBlock, if (ctx.chance(3)) null else cb);

    var nodes: [4]*v.D_800F53B8_t = undefined;
    for (&nodes) |*slot| slot.* = ctx.alloc(v.D_800F53B8_t);
    const len = ctx.range(usize, 0, 4);
    for (0..len) |i| {
        const n = nodes[i];
        psx.put(&n.next, if (i + 1 < len) nodes[i + 1] else null);
        n.unkD1C.unk3A = ctx.edge(i16, &.{ 2, 3, 4, 4, 0, -1, 1, 5 });
        psx.setBits(n, "unk14_16", ctx.edge(u16, &.{ 0, 1, 0xFFFE, 0xFFFF }));

        var head: ?*v.func_800D4910_t = null;
        var k = ctx.range(u8, 0, 3);
        while (k > 0) : (k -= 1) {
            const rn = ctx.alloc(v.func_800D4910_t);
            rn.next = head;
            rn.renderer = @ptrCast(&renderStub);
            rn.unk8 = @ptrFromInt(@as(usize, ctx.pick(u32, &.{ 0, 0x8000_0000, 1, 0xFFFF_FFFF })));
            head = rn;
        }
        psx.put(&n.unkD1C.unk34, head);
    }
    v.g.D_800F54B0().* = if (len == 0) null else nodes[0];
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const head = v.g.D_800F54B0().* orelse return 0;
    const cls = head.unkD1C.unk3A;
    if (cls == 2) return 1;
    if (cls == 3) return 2;
    if (cls == 4) {
        const blk = v.g.D_800F569C().*.?;
        return if (psx.get(blk.curveBlock) != null) 3 else 4;
    }
    return 5;
}
