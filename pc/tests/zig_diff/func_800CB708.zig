//! zig_diff spec: func_800CB708 -> func_800CB708.func_800CB708 (5BF94.c).
//! Inputs: the global D_800EB9B4 is null (1 in 8) or points at an arena object
//! with a random unk0 (zero half the time), unk2 and unk8 drawn from edges
//! (0, 1, sign-bit and extreme values), and the 32-bit word at unk4 set to
//! exactly 0x1000 (unk6 zero, or nonzero so only the low half matches), near
//! misses (0x0FFF, 0x1001, -0x1000), or random. The three callees are stubs
//! that change unk2, unk8 and the global, so a port that caches those fields
//! before the calls differs.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CB708));

pub const classes = [_][:0]const u8{ "null-object", "unk0-set", "word-0x1000", "low-half-0x1000", "other" };

pub const stubs = struct {
    pub fn _loadScreff2(ctx: *zd.Ctx, arg: anytype) void {
        _ = arg;
        if (ctx.value(u2) == 0) v.g.D_800EB9B4().* = null;
    }

    pub fn pc_screff2_warp(ctx: *zd.Ctx) void {
        const t = v.g.D_800EB9B4().* orelse return;
        if (ctx.value(u1) == 1) t.unk2 = ctx.value(u16);
    }

    pub fn pc_screff2_tiles(ctx: *zd.Ctx) void {
        const t = v.g.D_800EB9B4().* orelse return;
        if (ctx.value(u1) == 1) t.unk8 = ctx.value(i32);
        if (ctx.value(u3) == 0) v.g.D_800EB9B4().* = null;
    }

    pub fn pc_screff2_border(ctx: *zd.Ctx) void {
        _ = ctx;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const g = v.g.D_800EB9B4();
    if (ctx.chance(8)) {
        g.* = null;
        return .{};
    }
    const obj = ctx.alloc(v.D_800EB9B4_t);
    obj.unk0 = if (ctx.chance(2)) 0 else ctx.int(u8);
    obj.unk2 = ctx.pick(u16, &.{ 0, 1, 0x8000, 0xFFFF });
    obj.unk8 = ctx.pick(i32, &.{ 0, 1, -1, std.math.minInt(i32), std.math.maxInt(i32) });
    switch (ctx.range(u8, 0, 3)) {
        0 => {
            obj.unk4 = 0x1000;
            obj.unk6 = 0;
        },
        1 => {
            obj.unk4 = 0x1000;
            obj.unk6 = ctx.pick(i16, &.{ 1, -1, 0x1000 });
        },
        2 => {
            obj.unk4 = ctx.pick(i16, &.{ 0, 0x0FFF, 0x1001, -0x1000 });
            obj.unk6 = 0;
        },
        else => {
            obj.unk4 = ctx.int(i16);
            obj.unk6 = ctx.int(i16);
        },
    }
    g.* = obj;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const t = v.g.D_800EB9B4().* orelse return 0;
    if (t.unk0 != 0) return 1;
    if (t.unk4 == 0x1000 and t.unk6 == 0) return 2;
    if (t.unk4 == 0x1000) return 3;
    return 4;
}
