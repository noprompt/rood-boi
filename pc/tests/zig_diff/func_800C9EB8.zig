//! zig_diff spec: func_800C9EB8 -> func_800C9EB8.func_800C9EB8 (5BF94.c).
//! Inputs: arg0 across the switch (the four spell classes 0-3, case 4, chain
//! abilities 5 and 6, break arts 7, and default: negatives, 8, INT_MIN and
//! INT_MAX). The C reads no global. Its three callees are recording stubs
//! whose return values hit both the zero and the nonzero side of each test
//! (and the sign bit of func_800CABE0's result, which feeds the mask tests).
//! The callees write no state the C reads back, so the stubs write nothing.
const std = @import("std");
const zd = @import("zdiff");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800C9EB8));

pub const classes = [_][:0]const u8{ "spell-classes", "case-4", "chain-abilities", "break-arts", "default" };

/// A callee's flag: zero about a quarter of the time, otherwise nonzero.
fn flag(ctx: *zd.Ctx) c_int {
    if (ctx.value(u2) == 0) return 0;
    const r = ctx.value(c_int);
    return if (r == 0) 1 else r;
}

pub const stubs = struct {
    pub fn func_800CABE0(ctx: *zd.Ctx, id: anytype) c_int {
        _ = id;
        // temp_s0: tested with masks 0xB7, 0x7 and 0x15F, so it is often
        // zero under the mask and often has the sign bit set.
        if (ctx.value(u2) == 0) return 0;
        return ctx.value(c_int);
    }

    pub fn vs_battle_isSpellClassUnlocked(ctx: *zd.Ctx, spellClass: anytype) c_int {
        _ = spellClass;
        return flag(ctx);
    }

    pub fn vs_battle_chainAbilitiesUnlocked(ctx: *zd.Ctx, id: anytype) c_int {
        _ = id;
        return flag(ctx);
    }

    pub fn _breakArtsUnlocked(ctx: *zd.Ctx) c_int {
        return flag(ctx);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const edges = [_]c_int{ 0, 1, 2, 3, 4, 5, 6, 7, 8, -1, std.math.minInt(c_int), std.math.maxInt(c_int) };
    const arg: c_int = if (ctx.chance(4)) ctx.range(c_int, -3, 9) else ctx.edge(c_int, &edges);
    return .{arg};
}

pub fn classify(args: Args) usize {
    return switch (args[0]) {
        0...3 => 0,
        4 => 1,
        5, 6 => 2,
        7 => 3,
        else => 4,
    };
}
