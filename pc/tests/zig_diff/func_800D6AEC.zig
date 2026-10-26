//! zig_diff spec: func_800D6AEC -> func_800D6AEC.func_800D6AEC (5BF94.c).
//! Inputs: a D_800F53B8_t whose unkD1C.unk30 points at an arena timeline of
//! 0-32 entries (the loop bound), a random bitmask (unk4, sign bit both ways),
//! random flags (unk1: the gate bit and the bit-1 argument), a counter near
//! the i16 wrap, and every entry type the C handles (1-10, 12, 13). Each
//! callee's stub sometimes nulls the timeline or rewrites its flags and
//! bitmask (what the C reads back), and returns 0 about a third of the time
//! so the clear-bit store and the NULL guards run. Types 0 and 11 leave the
//! C's `temp` unset, so the spec never builds them.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D6AEC));

pub const classes = [_][:0]const u8{ "empty", "gate-set", "flag2-only", "neither", "counter-max" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const owner = ctx.alloc(v.D_800F53B8_t);
    const tl_bytes = ctx.allocBytes(8 + 16 * 32, 16);
    const tl: *v.D_800F53B8_t4 = @ptrCast(@alignCast(tl_bytes));
    tl.unk0 = ctx.range(u8, 0, 32);
    tl.unk1 = ctx.int(u8);
    tl.unk2 = ctx.pick(i16, &.{ 32767, -32768, -1, 0 });
    tl.unk4 = ctx.int(i32);
    // Entry k lives at byte 8 + 16k; its unk4.unk0_0 type byte is at 12 + 16k.
    for (0..32) |k| {
        tl_bytes[12 + 16 * k] = ctx.edge(u8, &.{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13 });
    }
    psx.put(&owner.unkD1C.unk30, tl);
    return .{ owner, ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000 }) };
}

pub fn classify(args: Args) usize {
    const owner = args[0].?;
    const tl = psx.get(owner.unkD1C.unk30).?;
    if (tl.unk0 == 0) return 0;
    if (tl.unk2 == 32767) return 4;
    if ((tl.unk1 & 1) != 0) return 1;
    if ((tl.unk1 & 2) != 0) return 2;
    return 3;
}

/// What a callee can do to the state the loop reads back: it may end the
/// effect (null the timeline, which the C's ROOD guards must catch), or
/// rewrite the timeline's flags and bitmask. It returns 0 about a third of
/// the time (the C then clears the bit) and any other int otherwise.
fn after(ctx: *zd.Ctx, owner: anytype) c_int {
    const self: *v.D_800F53B8_t = @ptrCast(@alignCast(owner.?));
    switch (ctx.value(u8) % 4) {
        0 => psx.put(&self.unkD1C.unk30, @as(?*v.D_800F53B8_t4, null)),
        1 => {
            if (psx.get(self.unkD1C.unk30)) |tl| tl.unk4 = ctx.value(i32);
        },
        2 => {
            if (psx.get(self.unkD1C.unk30)) |tl| tl.unk1 = ctx.value(u8);
        },
        else => {},
    }
    if (ctx.value(u8) < 96) return 0;
    return ctx.value(c_int);
}

pub const stubs = struct {
    pub fn func_800D57FC(ctx: *zd.Ctx, a0: anytype, a1: anytype) c_int {
        _ = a1;
        return after(ctx, a0);
    }
    pub fn func_800D5904(ctx: *zd.Ctx, a0: anytype, a1: anytype) c_int {
        _ = a1;
        return after(ctx, a0);
    }
    pub fn func_800D5A98(ctx: *zd.Ctx, a0: anytype, a1: anytype, a2: anytype) c_int {
        _ = a1;
        _ = a2;
        return after(ctx, a0);
    }
    pub fn func_800D5D74(ctx: *zd.Ctx, a0: anytype, a1: anytype) c_int {
        _ = a1;
        return after(ctx, a0);
    }
    pub fn func_800D5E00(ctx: *zd.Ctx, a0: anytype, a1: anytype) c_int {
        _ = a1;
        return after(ctx, a0);
    }
    pub fn func_800D5F8C(ctx: *zd.Ctx, a0: anytype, a1: anytype) c_int {
        _ = a1;
        return after(ctx, a0);
    }
    pub fn func_800D6048(ctx: *zd.Ctx, a0: anytype, a1: anytype, a2: anytype) c_int {
        _ = a1;
        _ = a2;
        return after(ctx, a0);
    }
    pub fn func_800D61AC(ctx: *zd.Ctx, a0: anytype, a1: anytype) c_int {
        _ = a1;
        return after(ctx, a0);
    }
    pub fn func_800D6298(ctx: *zd.Ctx, a0: anytype, a1: anytype) c_int {
        _ = a1;
        return after(ctx, a0);
    }
    pub fn func_800D6310(ctx: *zd.Ctx, a0: anytype, a1: anytype) c_int {
        _ = a1;
        return after(ctx, a0);
    }
    pub fn func_800D6894(ctx: *zd.Ctx, a0: anytype, a1: anytype) c_int {
        _ = a1;
        return after(ctx, a0);
    }
    pub fn func_800D6A18(ctx: *zd.Ctx, a0: anytype, a1: anytype) c_int {
        _ = a1;
        return after(ctx, a0);
    }
};
