//! zig_diff spec: func_8007424C -> func_8007424C.func_8007424C (146C.c).
//! Inputs: no arguments, and the C reads no globals. The stub of func_800A0BE0
//! sets or clears bit 27 of its result, with random sign bits either way. When
//! bit 27 is set, func_800CB45C returns 0 or a nonzero value, so the taken and
//! not-taken branches and both results of `== 0` are reached.
const std = @import("std");
const zd = @import("zdiff");
const port = @import("port");

pub const Args = std.meta.ArgsTuple(@TypeOf(port.func_8007424C));

pub const classes = [_][:0]const u8{ "bit-clear", "bit-set-call-zero", "bit-set-call-nonzero" };

/// Chosen by prepare (once per iteration, before both runs); the stubs read them.
var bit_set: bool = false;
var call_zero: bool = false;

pub const stubs = struct {
    pub fn func_800A0BE0(ctx: *zd.Ctx, id: anytype) u32 {
        _ = id;
        const r = ctx.value(u32);
        return if (bit_set) r | 0x08000000 else r & ~@as(u32, 0x08000000);
    }

    pub fn func_800CB45C(ctx: *zd.Ctx) c_int {
        if (call_zero) return 0;
        const r = ctx.value(c_int);
        return if (r == 0) 1 else r;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    bit_set = !ctx.chance(3);
    call_zero = ctx.chance(3);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if (!bit_set) return 0;
    return if (call_zero) 1 else 2;
}
