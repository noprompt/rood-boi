//! zig_diff spec: func_8008C0C0 -> func_8008C0C0.func_8008C0C0 (146C.c).
//! Inputs: the count D_800F1D6A at or below zero (0, -1, the i16 minimum) or
//! positive (1, 2, 3, 8), and eight slots whose unk0 is 0-4 or -1, with each
//! unk4 null or pointing at an arena object. Slots in state 2 or 3 always get
//! an object, and its unkA (0, 1, 2, 127, 128, 129, 255) and unk13 (0, 1, 2,
//! 255) hit both sides of the `<< 0x18 <= 0` sign test and the unk13 zero test.
//! The callee stubs return 0 and nonzero, and sometimes clear a random slot's
//! unk0, which the C re-reads in the loop.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008C0C0));

pub const classes = [_][:0]const u8{
    "count-not-positive",
    "pending-slot",
    "countdown-slot",
    "field-timer-slot",
    "idle",
};

fn clearSlot(ctx: *zd.Ctx) void {
    // The callee may free another slot; the C re-reads unk0 in its loop.
    if (ctx.value(u2) == 0) v.g.D_800F1D28()[ctx.value(u3)].unk0 = 0;
}

pub const stubs = struct {
    pub fn func_8008C1C8(ctx: *zd.Ctx, arg0: anytype) c_int {
        _ = arg0;
        clearSlot(ctx);
        if (ctx.value(u2) == 0) return 0; // the C's "!= 0" test sees zero
        return ctx.value(c_int) | 1;
    }

    pub fn func_8008BF48(ctx: *zd.Ctx, arg0: anytype) c_int {
        _ = arg0;
        clearSlot(ctx);
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const slots = v.g.D_800F1D28();
    const count = v.g.D_800F1D6A();
    const mode = ctx.range(u8, 0, 4);

    count.* = if (mode == 0)
        ctx.edge(i16, &.{ 0, -1, -32768 })
    else
        ctx.edge(i16, &.{ 1, 2, 3, 8 });

    for (slots) |*s| {
        s.unk0 = if (mode == 0)
            ctx.edge(i32, &.{ 0, 1, 2, 3, 4, -1 })
        else
            ctx.edge(i32, &.{ 1, 2, 3, 0, 4 });

        const needs_object = s.unk0 == 2 or s.unk0 == 3;
        if (!needs_object and ctx.chance(4)) {
            psx.put(&s.unk4, null);
        } else {
            const obj = ctx.alloc(v._mpdRoomSectionA);
            obj.unk0.unkA = ctx.edge(u8, &.{ 0, 1, 2, 127, 128, 129, 255 });
            obj.unk13 = ctx.edge(u8, &.{ 0, 1, 2, 255 });
            psx.put(&s.unk4, obj);
        }
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if (v.g.D_800F1D6A().* <= 0) return 0;
    const slots = v.g.D_800F1D28();
    for (slots) |s| {
        if (s.unk0 == 1) return 1;
    }
    for (slots) |s| {
        if (s.unk0 == 2) return 2;
    }
    for (slots) |s| {
        if (s.unk0 == 3) return 3;
    }
    return 4;
}
