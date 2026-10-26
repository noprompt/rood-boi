//! zig_diff spec: func_8006C250 -> func_8006C250.func_8006C250 (146C.c).
//! The C takes no arguments: it walks slots 0-15, asks func_800A0BE0 for each
//! slot's word and, where bit 2 is clear, writes the word back with bit 2 set
//! through func_800A087C. The spec's mode (set by prepare, so the same in both
//! runs) decides what func_800A0BE0 returns: bit 2 always set (no setter
//! calls), bit 2 always clear (a setter call on every slot), or random bits
//! (a mix). Every return is a ctx.value draw, so the slot words differ per call.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006C250));

pub const classes = [_][:0]const u8{ "bit2-set", "bit2-clear", "mixed" };

var mode: u8 = 0;

pub const stubs = struct {
    /// The slot word: its bit 2 is set or cleared by mode, or left random.
    /// Typed as the C prototype's c_uint return.
    pub fn func_800A0BE0(ctx: *zd.Ctx, i: anytype) c_uint {
        _ = i;
        const t = ctx.value(c_uint);
        return switch (mode) {
            0 => t | 4,
            1 => t & ~@as(c_uint, 4),
            else => t,
        };
    }
    // func_800A087C is a void setter the C never reads back from: the
    // default recording stub (does nothing) models it.
};

pub fn prepare(ctx: *zd.Ctx) Args {
    mode = ctx.range(u8, 0, 2);
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return mode;
}
