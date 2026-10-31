//! zig_diff spec: func_800CF988 -> func_800CF988.func_800CF988 (5BF94.c).
//! Inputs: a random func_800CF988_t whose four unk8[k].unk4 are drawn from
//! edges (320 and its neighbours, 0, -1, -64, 63, 32767, -32768) or all set
//! to one shared value, so the running minimum ties often; frameBuf with both
//! parities; arg1 and arg3 at the edges (wrapping subtraction, the 0x100 flag,
//! negative values). The callee func_800CF92C is a recording stub that reads
//! its element's unkA and writes its unk8, and sometimes writes unkA.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF988));

pub const classes = [_][:0]const u8{ "keeps-320", "min-0", "min-1", "min-2", "min-3", "negative-min" };

pub const stubs = struct {
    pub fn func_800CF92C(ctx: *zd.Ctx, offset: anytype, arg2: anytype, value: anytype, out: anytype) void {
        _ = offset;
        _ = arg2;
        _ = value;
        // `out` is &element.unk8; the element's unkA is two bytes further on.
        const bytes: [*]u8 = @ptrCast(out);
        const field: *align(1) i16 = @ptrCast(bytes + 0);
        const tail: *align(1) i16 = @ptrCast(bytes + 2);
        field.* = tail.* +% ctx.value(i16);
        if (ctx.value(u1) == 1) tail.* = ctx.value(i16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const f = ctx.alloc(v.func_800CF988_t);
    const edges = [_]i16{ 320, 319, 321, 64, 0, -1, -64, 63, 32767, -32768 };
    if (ctx.chance(5)) {
        const shared = ctx.pick(i16, &edges);
        for (&f.unk8) |*e| e.unk4 = shared;
    } else {
        for (&f.unk8) |*e| e.unk4 = ctx.pick(i16, &edges);
    }
    v.g.vs_main_frameBuf().* = ctx.pick(i32, &.{ 0, 1, 2, 3, -1, -2, 0x7FFF_FFFF });
    const arg1 = ctx.pick(i32, &.{ 0, 1, 320, 64, -1, 0x7FFF_FFFF, -0x8000_0000 });
    const arg2 = ctx.pick(i32, &.{ 0, 1, -1, 240, 0x7FFF_FFFF });
    const arg3 = ctx.pick(i32, &.{ 0, 1, 0x100, -1, 0x7FFF_FFFF, -0x8000_0000 });
    return .{ f, arg1, arg2, arg3 };
}

pub fn classify(args: Args) usize {
    const f = args[0].?;
    var left: i32 = 320;
    var which: usize = 0;
    var found = false;
    for (0..4) |k| {
        const x: i32 = f.unk8[k].unk4;
        if (x < left) {
            left = x;
            which = k;
            found = true;
        }
    }
    if (!found) return 0;
    if (left < 0) return 5;
    return 1 + which;
}
