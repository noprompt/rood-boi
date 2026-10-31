//! zig_diff spec: func_800D1104 -> func_800D1104.func_800D1104 (5BF94.c).
//! Inputs: a curve block in the arena with count 0, 1, 2 to 31, or 32 (the
//! count is 0 or 32 about one time in eight each, so the loop's entry and
//! exit both occur often). Each curve is an arena buffer with 256 bytes of
//! room before and after its start, so a negative index (arg0 % size) stays
//! inside memory the harness owns. Curve sizes are 1 to 255 (never 0, which
//! the C divides by). arg0 is an edge value half the time (0, +-1, the 256
//! boundary, INT_MIN and INT_MAX) and any c_int otherwise.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D1104));

pub const classes = [_][:0]const u8{ "empty", "single", "many", "full" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const block: *v.pFileCurveBlock = @ptrCast(@alignCast(ctx.allocBytes(64, 16)));
    const count: u16 = if (ctx.chance(8)) 0 else if (ctx.chance(8)) 32 else ctx.range(u16, 1, 32);
    block.count = count;

    const obj = ctx.alloc(v.D_800F569C_t);
    psx.put(&obj.curveBlock, block);
    v.g.D_800F569C().* = obj;

    var i: usize = 0;
    while (i < 32) : (i += 1) {
        const buf = ctx.allocBytes(512, 16);
        const base: *u8 = @ptrCast(buf + 256);
        psx.put(&obj.curves[i], base);
        const size: u8 = if (ctx.chance(2))
            ctx.edge(u8, &.{ 1, 2, 3, 4, 8, 16, 100, 128, 255 })
        else
            ctx.range(u8, 1, 255);
        psx.byteAt(u8, block, 4 + @as(isize, @intCast(i))).* = size;
    }

    const arg: c_int = ctx.pick(c_int, &.{
        0,
        1,
        -1,
        2,
        -2,
        255,
        256,
        -256,
        std.math.maxInt(c_int),
        std.math.minInt(c_int),
    });
    return .{arg};
}

pub fn classify(args: Args) usize {
    _ = args;
    const obj = v.g.D_800F569C().*.?;
    const count = psx.get(obj.curveBlock).?.count;
    if (count == 0) return 0;
    if (count == 1) return 1;
    if (count == 32) return 3;
    return 2;
}
