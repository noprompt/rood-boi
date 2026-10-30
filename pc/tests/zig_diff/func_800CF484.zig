//! zig_diff spec: func_800CF484 -> func_800CF484.func_800CF484 (5BF94.c).
//! The C is one store: `arg1->unkD1C.unk3A = arg0;`, an int narrowed to an i16 field
//! of a D_800F53B8_t object. The inputs are a valid object in the arena and an
//! arg0 drawn from the i16 and i32 edges (0, -1, 32767, -32768, 65535, 65536, the
//! int extremes) plus random values, so the narrowing wraps for values above and
//! below the i16 range and the high bits of arg0 vary. The C has no branches and
//! no callees; the classes split arg0 into values that fit an i16 and values
//! outside it.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF484));

pub const classes = [_][:0]const u8{ "fits-i16", "above-i16", "below-i16" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.D_800F53B8_t);
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, 32767, -32768, 32768, -32769, 65535, 65536, std.math.maxInt(c_int), std.math.minInt(c_int) });
    return .{ arg0, obj };
}

pub fn classify(args: Args) usize {
    const x = args[0];
    if (x < -32768) return 2;
    if (x > 32767) return 1;
    return 0;
}
