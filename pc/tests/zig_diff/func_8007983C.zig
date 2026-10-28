//! zig_diff spec: func_8007983C -> func_8007983C.func_8007983C (146C.c).
//! Inputs: the unit has no arguments, so the spec varies the object that
//! func_800CB66C returns (a 16-byte arena block whose first word is unk0)
//! and the two return values the C tests: unk0 equal to 1 (the && short-
//! circuits), unk0 not 1 with func_800CB45C returning nonzero (the four
//! calls are skipped), and unk0 not 1 with func_800CB45C returning 0 (the
//! four calls run). unk0 takes 0, 2, 0x10001, 0xFFFFFFFF and random words.
//! func_800C97BC may rewrite unk0 during the C run, so a port that reads
//! unk0 before that call differs.
const std = @import("std");
const zd = @import("zdiff");
const c = @import("c_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007983C));

pub const classes = [_][:0]const u8{ "unk0-is-one", "gate-closed", "gate-open" };

/// The object func_800CB66C returns; set by prepare.
var unk0_obj: [*]u8 = undefined;
/// The input class chosen by prepare (0, 1 or 2).
var mode: usize = 0;
/// Whether func_800CB45C returns 0 this run (the gate opens).
var want_zero: bool = false;

pub fn prepare(ctx: *zd.Ctx) Args {
    unk0_obj = ctx.allocBytes(16, 16);
    mode = ctx.range(usize, 0, 2);
    var x = ctx.int(u32);
    if (x == 1) x = 2;
    const choices = [_]u32{ 0, 2, 0x10001, 0xFFFF_FFFF, x };
    const word: *align(1) u32 = @ptrCast(unk0_obj);
    word.* = if (mode == 0) 1 else ctx.edge(u32, &choices);
    want_zero = mode == 2;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return mode;
}

pub const stubs = struct {
    /// Rewrites unk0 in some calls, so a read taken before it differs.
    pub fn func_800C97BC(ctx: *zd.Ctx) void {
        if (ctx.value(u8) < 64) {
            const word: *align(1) u32 = @ptrCast(unk0_obj);
            word.* = if (ctx.value(u8) < 128) 1 else ctx.value(u32);
        }
    }

    /// Always a valid object: the C dereferences it without a NULL test.
    pub fn func_800CB66C(ctx: *zd.Ctx) ?*c.D_800F18EC_t {
        _ = ctx;
        return @ptrCast(unk0_obj);
    }

    /// The C's gate: 0 opens it, nonzero (with and without the sign bit) closes it.
    pub fn func_800CB45C(ctx: *zd.Ctx) c_int {
        if (want_zero) return 0;
        return ctx.value(c_int) | 1;
    }
};
