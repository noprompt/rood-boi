//! zig_diff spec: func_800D2888 -> func_800D2888.func_800D2888 (5BF94.c).
//! Inputs: a node unlinked from a doubly linked list whose next and previous
//! links are each null, a fresh neighbour in the arena, the node itself, the
//! owner object reinterpreted as a node, or a neighbour at PS1 address 0x80000000
//! (raw values with the sign bit set). The free-list head is null, the node, a
//! neighbour or a high-address node. The owner's unk8 is 0, 1 or 255 (the
//! decrement wraps), and the free-list count sits at the edges of i32 (not
//! INT_MIN, which the C would overflow). The C calls nothing, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D2888));

pub const classes = [_][:0]const u8{ "no-next", "no-prev", "linked", "self-link", "high-link", "owner-link" };

fn linkChoice(
    ctx: *zd.Ctx,
    node: *v.func_800D2904_t,
    owner: *v.D_800F53B8_t,
    other: *v.func_800D2904_t,
    high: *v.func_800D2904_t,
) ?*v.func_800D2904_t {
    return switch (ctx.range(u8, 0, 9)) {
        0 => null,
        1 => node,
        2 => @as(*v.func_800D2904_t, @ptrCast(owner)),
        3 => high,
        else => other,
    };
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const node = ctx.alloc(v.func_800D2904_t);
    const owner = ctx.alloc(v.D_800F53B8_t);
    const other_a = ctx.alloc(v.func_800D2904_t);
    const other_b = ctx.alloc(v.func_800D2904_t);
    const high_a: *v.func_800D2904_t = @ptrFromInt(0x8000_0100);
    const high_b: *v.func_800D2904_t = @ptrFromInt(0x8000_4000);

    psx.put(&node.next, linkChoice(ctx, node, owner, other_a, high_a));
    psx.put(&node.previous, linkChoice(ctx, node, owner, other_b, high_b));

    owner.unk8 = ctx.pick(u8, &.{ 0, 1, 255 });

    v.g.D_800F55F8().* = ctx.edge(i32, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x7FFF_FFFF });
    // The free-list head is always a valid address: the C stores its address.
    v.g.D_800F55F4().* = switch (ctx.range(u8, 0, 3)) {
        0 => null,
        1 => other_b,
        2 => node,
        else => high_b,
    };

    return .{ node, owner };
}

pub fn classify(args: Args) usize {
    const node = args[0].?;
    const owner = args[1].?;
    const n = psx.rawOf(node.next);
    const p = psx.rawOf(node.previous);
    if (n == 0) return 0;
    if (p == 0) return 1;
    if (n == psx.addr(node) or p == psx.addr(node)) return 3;
    if (n >= 0x8000_0000 or p >= 0x8000_0000) return 4;
    if (n == psx.addr(owner) or p == psx.addr(owner)) return 5;
    return 2;
}
