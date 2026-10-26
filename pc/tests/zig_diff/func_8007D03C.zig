//! zig_diff spec: func_8007D03C -> func_8007D03C.func_8007D03C (146C.c).
//! Inputs: any arg0 (the id the callee is passed, edge values included). The
//! callee's result is chosen per iteration: 0 (the ok path, which passes
//! func_800A0A74's result with bit 1 cleared to func_800A0A1C), 2 (returns
//! the comparison true), or another odd value (never 0 or 2). func_800A0A74
//! returns random 32-bit values, so bit 1 is set and clear both ways and the
//! sign bit is tested with and without.
const std = @import("std");
const zd = @import("zdiff");
const Port = @import("port");

pub const Args = std.meta.ArgsTuple(@TypeOf(Port.func_8007D03C));

pub const classes = [_][:0]const u8{ "ret-zero", "ret-two", "ret-other" };

/// Which result the callee gives this iteration (set by prepare, read by the
/// stub; identical in the C run and the Zig run).
var result: u8 = 0;

pub const stubs = struct {
    /// The C's `temp_v0`: declared `int func_800E5154()`, so no parameters.
    /// 0, 2, or an odd value that is neither.
    pub fn func_800E5154(ctx: *zd.Ctx) c_int {
        return switch (result) {
            0 => 0,
            1 => 2,
            else => @bitCast(ctx.value(u32) | 1),
        };
    }

    /// The flag word the C masks with `~2`: any 32-bit value.
    pub fn func_800A0A74(ctx: *zd.Ctx, id: anytype) c_int {
        _ = id;
        return @bitCast(ctx.value(u32));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    result = ctx.edge(u8, &.{ 0, 1, 2 });
    const id = ctx.pick(c_int, &.{ 0, 1, 2, -1, 0x7FFF_FFFF, -0x8000_0000 });
    return .{id};
}

pub fn classify(args: Args) usize {
    _ = args;
    return result;
}
