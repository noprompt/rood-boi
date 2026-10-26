//! zig_diff spec: _applyArmorStats -> apply_armor_stats.applyArmorStats (146C.c).
//! Inputs: a random uiArmor target and a random _armorIntermediate source, both
//! in the arena. The equipment bytes are random, so the i8 fields (types,
//! classes, affinities) are negative about half the time and sign-extend into
//! the i16/u16 destinations. Some calls clear the sign bits, so the
//! all-nonnegative case also occurs. The memcpy stub really copies its bytes,
//! so a port that orders its stores around the copy differs.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").applyArmorStats));

pub const classes = [_][:0]const u8{ "all-nonnegative", "some-negative" };

pub const stubs = struct {
    /// The real callee copies `sz` bytes from `src` to `dest`.
    pub fn vs_main_memcpy(ctx: *zd.Ctx, dest: anytype, src: anytype, sz: anytype) void {
        _ = ctx;
        const d: [*]u8 = @ptrCast(dest.?);
        const s: [*]const u8 = @ptrCast(src.?);
        const n: usize = @as(usize, sz);
        @memcpy(d[0..n], s[0..n]);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_battle_uiArmor);
    const source = ctx.alloc(v._armorIntermediate);
    if (ctx.chance(4)) {
        // Clear the sign bits so the all-nonnegative class occurs.
        for (&source.equip.types) |*x| x.* &= 0x7f;
        for (&source.equip.classes) |*x| x.* &= 0x7f;
        for (&source.equip.affinities) |*x| x.* &= 0x7f;
    }
    if (ctx.chance(3)) {
        // Sign-bit edges for the i8 -> i16 / u16 conversions.
        source.equip.types[0] = ctx.pick(i8, &.{ -1, -128, 127 });
        source.equip.classes[ctx.range(usize, 0, 5)] = ctx.pick(i8, &.{ -1, -128, 127 });
        source.equip.affinities[ctx.range(usize, 0, 6)] = ctx.pick(i8, &.{ -1, -128, 127 });
    }
    return .{ target, source };
}

pub fn classify(args: Args) usize {
    const s = args[1].?;
    for (s.equip.types) |x| if (x < 0) return 1;
    for (s.equip.classes) |x| if (x < 0) return 1;
    for (s.equip.affinities) |x| if (x < 0) return 1;
    return 0;
}
