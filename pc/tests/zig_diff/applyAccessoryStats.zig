//! zig_diff spec: _applyAccessoryStats -> apply_accessory_stats.applyAccessoryStats (146C.c).
//! Inputs: a uiAccessory and an _accessoryIntermediate in the arena, kept
//! disjoint. Strength, intelligence and agility take the i8 edges -128, -1,
//! 0 and 127 (sign extension into the i16 fields), and the drop rate and index
//! take 0 and 255. The rest of the source equip block is random bytes, so the
//! i8 arrays (types, classes, affinities) carry negative values too. The C's
//! only branches are its constant-bound loops, which every input takes. The
//! memcpy stub copies sz bytes, as the real callee does, so a port that reads
//! target->accessory before the call, or skips the copy, is caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").applyAccessoryStats));

pub const classes = [_][:0]const u8{ "neg-strength", "nonneg-strength" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const target = ctx.alloc(v.vs_battle_uiAccessory);
    const source = ctx.alloc(v._accessoryIntermediate);
    const e = &source.equip;
    e.strength = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    e.intelligence = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    e.agility = ctx.pick(i8, &.{ -128, -1, 0, 127 });
    source.dropRate = ctx.pick(u8, &.{ 0, 255 });
    source.index = ctx.pick(u8, &.{ 0, 255 });
    return .{ target, source };
}

pub fn classify(args: Args) usize {
    const s = args[1].?;
    return if (s.equip.strength < 0) 0 else 1;
}

pub const stubs = struct {
    /// The real memcpy writes sz bytes at dest: model that, so the C reads back the copy.
    pub fn vs_main_memcpy(ctx: *zd.Ctx, dest: anytype, src: anytype, sz: anytype) void {
        _ = ctx;
        const n: usize = @intCast(sz);
        const d: [*]u8 = @ptrCast(dest.?);
        const s: [*]const u8 = @ptrCast(src.?);
        @memcpy(d[0..n], s[0..n]);
    }
};
