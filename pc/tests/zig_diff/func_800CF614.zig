//! zig_diff spec: func_800CF614 -> func_800CF614.func_800CF614 (5BF94.c).
//! Inputs: a global list of 3-4 arena nodes whose head is never null, with the
//! freed node as the head, a middle node, the last node, or a node not in the
//! list (the walk then ends on a null next). Node next fields are real arena
//! pointers or null. func_800D2904 is a stub that rewrites the freed node's
//! unk14 bitfields, which the C reads back for func_800CF514's argument.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF614));

pub const classes = [_][:0]const u8{ "head", "middle", "last", "absent" };

// Which class prepare built; classify reports it (globals are as prepare left them).
var chosen: usize = 0;

pub const stubs = struct {
    pub fn func_800D2904(ctx: *zd.Ctx, p: anytype) void {
        const a: *v.D_800F53B8_t = @ptrCast(@alignCast(p.?));
        psx.setBits(a, "unk14_0", ctx.value(u8));
        if (ctx.value(u1) == 1) psx.setBits(a, "unk14_16", ctx.value(u16));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const n: usize = ctx.range(usize, 3, 4);
    var nodes: [4]*v.D_800F53B8_t = undefined;
    for (0..n) |i| nodes[i] = ctx.alloc(v.D_800F53B8_t);
    const outside = ctx.alloc(v.D_800F53B8_t);

    // Link the chain; the last node's next is a real null.
    for (0..n) |i| {
        if (i + 1 < n) {
            psx.put(&nodes[i].next, nodes[i + 1]);
        } else {
            nodes[i].next.raw = 0;
        }
    }
    outside.next.raw = 0;

    v.g.D_800F54B0().* = nodes[0];

    const kind = ctx.range(usize, 0, 3);
    const target: *v.D_800F53B8_t = switch (kind) {
        0 => nodes[0],
        1 => nodes[ctx.range(usize, 1, n - 2)],
        2 => nodes[n - 1],
        else => outside,
    };
    chosen = kind;
    return .{target};
}

pub fn classify(args: Args) usize {
    _ = args;
    return chosen;
}
