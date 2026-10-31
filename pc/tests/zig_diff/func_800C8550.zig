//! zig_diff spec: func_800C8550 -> func_800C8550.func_800C8550 (5BF94.c).
//! Inputs: a 128-entry gim_t table in the arena behind the D_800EB9BC pointer,
//! an index 0..127 (0, 1 and 127 as edges), the entry's unk0_3 mode set to 2,
//! 3 or any other value, and entry 0's unk0_9 random (it is the one the
//! mode-3 call reads). The keystream stub returns values in a small range half
//! the time, so the 240-step angle/target loop meets its equal and negative
//! cases often; rsin returns any i16-range value (negative included) and
//! func_8007DFF0 any int. The angle passed to rsin is recorded, so the angle
//! trajectory (and thus each target comparison) is visible in the call trace.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800C8550));

pub const classes = [_][:0]const u8{ "mode-2", "mode-3", "other" };

pub const stubs = struct {
    pub fn vs_battle_keystreamBits(ctx: *zd.Ctx, value: anytype) c_uint {
        const n: u5 = @intCast(value);
        const small = ctx.value(u8) < 96;
        const mask: u32 = if (small) 7 else (@as(u32, 1) << n) - 1;
        return ctx.value(u32) & mask;
    }

    pub fn rsin(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        return @as(c_int, ctx.value(i16));
    }

    pub fn func_8007DFF0(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) c_int {
        _ = a;
        _ = b;
        _ = c;
        return ctx.value(c_int);
    }
};

const table_len = 128;

pub fn prepare(ctx: *zd.Ctx) Args {
    const table: [*]v.gim_t = @ptrCast(@alignCast(ctx.allocBytes(table_len * @sizeOf(v.gim_t), 16)));
    v.g.D_800EB9BC().* = @ptrCast(table);
    psx.setBits(&table[0], "unk0_9", ctx.int(u3));

    const idx: c_uint = if (ctx.chance(3)) ctx.edge(c_uint, &.{ 0, 1, 127 }) else ctx.range(c_uint, 0, 127);
    const gim = &table[idx];
    const mode: u3 = if (ctx.chance(3)) 2 else if (ctx.chance(2)) 3 else ctx.int(u3);
    psx.setBits(gim, "unk0_3", mode);

    var a1: ?*anyopaque = null;
    if (!ctx.chance(2)) a1 = @ptrCast(ctx.allocBytes(16, 16));
    var a2: [*c]u8 = null;
    if (!ctx.chance(2)) a2 = ctx.allocBytes(16, 16);

    return .{ idx, a1, a2 };
}

pub fn classify(args: Args) usize {
    const base: [*]v.gim_t = @ptrCast(v.g.D_800EB9BC().*.?);
    const gim = &base[args[0]];
    return switch (psx.getBits(gim, "unk0_3")) {
        2 => 0,
        3 => 1,
        else => 2,
    };
}
