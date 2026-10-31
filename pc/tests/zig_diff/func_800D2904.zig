//! zig_diff spec: func_800D2904 -> func_800D2904.func_800D2904 (5BF94.c).
//! Inputs: a D_800F53B8_t in the arena whose unk18 is null or a chain of 1-4
//! func_800D2904_t nodes (so the loop runs 0, 1, or 2+ times), the global list
//! head D_800F55F4 null, an arena node, or the chain head, and D_800F55F8 at
//! the wrap edges (the minInt edge is kept 255 above the minimum, so the
//! subtraction of a u8 stays defined). unk8 takes 0, 1, 127, 128 and 255 so
//! unsigned and signed reads differ, and unk9 is random so a field slip shows.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D2904));

pub const classes = [_][:0]const u8{ "head-null", "one-node", "chain" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.alloc(v.D_800F53B8_t);

    // Build a chain of 0..4 nodes; each new node's next is the previous head.
    const count = ctx.range(u8, 0, 4);
    var head: ?*v.func_800D2904_t = null;
    var k: u8 = 0;
    while (k < count) : (k += 1) {
        const node = ctx.alloc(v.func_800D2904_t);
        psx.put(&node.next, head);
        head = node;
    }
    psx.put(&arg0.unk18, head);

    // The global list head: null, an unrelated node, or the chain's head.
    const other = ctx.alloc(v.func_800D2904_t);
    const g = v.g.D_800F55F4();
    g.* = if (ctx.chance(3)) null else if (ctx.chance(2)) head else other;

    arg0.unk8 = ctx.pick(u8, &.{ 0, 1, 127, 128, 255 });
    v.g.D_800F55F8().* = ctx.pick(i32, &.{ 0, -1, 1, std.math.maxInt(i32), std.math.minInt(i32) + 255 });

    return .{arg0};
}

pub fn classify(args: Args) usize {
    const head = psx.get(args[0].?.unk18) orelse return 0;
    if (psx.get(head.next) == null) return 1;
    return 2;
}
