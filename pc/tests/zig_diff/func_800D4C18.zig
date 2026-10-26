//! zig_diff spec: func_800D4C18 -> func_800D4C18.func_800D4C18 (5BF94.c).
//! Inputs: an arg0 in the arena whose unk18 heads a list of 0-4 arena nodes,
//! or is null (1 in 6). Each node gets a random age, a tickEvent and endEvent
//! from {0, 1, 2, 128, 255} or any byte, a lifetime from {-1, 1, 2, 0, -2,
//! i16 min, i16 max} or any i16, and byte 0x42 from {0, 1, 0x80, 0xFF} or any
//! byte. The lists are acyclic and every link is an arena node or null. The
//! stubs write what the C reads back after each call: the list links and the
//! head's lifetime after func_800D52A4, the tickEvent and lifetime after
//! func_800D6E44, the lifetime and endEvent after func_800D2ADC, and the
//! lifetime, the node's next and arg0's head after func_800D2888. They also
//! return nothing, since every callee is void.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D4C18));

const Node = v.func_800D2904_t;

pub const classes = [_][:0]const u8{ "no-list", "immortal-hidden", "immortal-ends", "expires", "alive" };

fn setNode(ctx: *zd.Ctx, node: *Node) void {
    node.unk74.fields.age = ctx.int(u8);
    node.tickEvent = ctx.pick(u8, &.{ 0, 1, 2, 128, 255 });
    node.endEvent = ctx.pick(u8, &.{ 0, 1, 2, 128, 255 });
    node.lifetime = ctx.pick(i16, &.{ -1, -1, 1, 2, 0, -2, -32768, 32767 });
    const bytes: [*]u8 = @ptrCast(node);
    bytes[0x42] = ctx.pick(u8, &.{ 0, 1, 0x80, 0xFF });
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.alloc(v.D_800F53B8_t);
    const count: u8 = if (ctx.chance(6)) 0 else ctx.range(u8, 1, 4);
    var head: ?*Node = null;
    var prev: ?*Node = null;
    var i: u8 = 0;
    while (i < count) : (i += 1) {
        const node = ctx.alloc(Node);
        setNode(ctx, node);
        if (prev) |p| {
            psx.put(&p.next, node);
        } else {
            head = node;
        }
        prev = node;
    }
    if (prev) |p| {
        psx.put(&p.next, @as(?*Node, null));
    }
    psx.put(&arg0.unk18, head);
    return .{arg0};
}

pub fn classify(args: Args) usize {
    const head = psx.get(args[0].?.unk18) orelse return 0;
    const bytes: [*]u8 = @ptrCast(head);
    if (head.lifetime == -1) return if (bytes[0x42] == 0) 2 else 1;
    if (head.lifetime == 1) return 3;
    return 4;
}

pub const stubs = struct {
    pub fn func_800D52A4(ctx: *zd.Ctx, p: anytype) void {
        if (p) |raw| {
            const node: *Node = @ptrCast(@alignCast(raw));
            if (ctx.value(bool)) psx.put(&node.next, @as(?*Node, null));
            if (ctx.value(bool)) node.lifetime = ctx.value(i16);
        }
    }

    pub fn func_800D6E44(ctx: *zd.Ctx, particles: anytype) void {
        if (particles) |raw| {
            const node: *Node = @ptrCast(@alignCast(raw));
            if (ctx.value(bool)) node.tickEvent = ctx.value(u8);
            if (ctx.value(bool)) node.lifetime = ctx.value(i16);
        }
    }

    pub fn func_800D2ADC(ctx: *zd.Ctx, arg0: anytype, event: anytype, a: anytype, b: anytype, node: anytype) void {
        _ = arg0;
        _ = event;
        _ = a;
        _ = b;
        if (node) |raw| {
            const n: *Node = @ptrCast(@alignCast(raw));
            if (ctx.value(bool)) n.lifetime = ctx.value(i16);
            if (ctx.value(bool)) n.endEvent = ctx.value(u8);
        }
    }

    pub fn func_800D2888(ctx: *zd.Ctx, node: anytype, arg1: anytype) void {
        if (node) |raw| {
            const n: *Node = @ptrCast(@alignCast(raw));
            if (ctx.value(bool)) n.lifetime = ctx.value(i16);
            if (ctx.value(bool)) psx.put(&n.next, @as(?*Node, null));
        }
        if (arg1) |raw| {
            const o: *v.D_800F53B8_t = @ptrCast(@alignCast(raw));
            if (ctx.value(bool)) psx.put(&o.unk18, @as(?*Node, null));
        }
    }
};
