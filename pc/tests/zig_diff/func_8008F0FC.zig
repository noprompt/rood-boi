//! zig_diff spec: func_8008F0FC -> func_8008F0FC.func_8008F0FC (146C.c).
//! Inputs: the CD queue slot in D_800F1DAC (streamed, state 4, or not), the
//! slot in D_800F1DB0 (state 4 or not), the heap block in D_800F1DD0 (or
//! null), and D_800F1DC8 with its bits 0-4 edge values. parseTim's stub
//! picks the TIM's image and CLUT pointers (each present or null) and writes
//! a random rect (signed x and y, so the `(char)` narrowing of y sees both
//! signs), so every branch of the upload path runs. The free stubs write the
//! block header and the slot state the C never reads back.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008F0FC));

pub const classes = [_][:0]const u8{ "upload-slot", "free-heap", "free-heap-null", "idle" };

// Objects prepare builds; the stubs read and write them.
var rect: *v.RECT = undefined;
var img: *u32 = undefined;
var clut: *u32 = undefined;

pub fn prepare(ctx: *zd.Ctx) Args {
    rect = ctx.alloc(v.RECT);
    img = ctx.alloc(u32);
    clut = ctx.alloc(u32);
    const block: [*]u32 = ctx.alloc([16]u32);
    const slot_a = ctx.alloc(v.vs_main_CdQueueSlot);
    const slot_b = ctx.alloc(v.vs_main_CdQueueSlot);

    // Any state but 4 for the slots that must not match.
    const other = ctx.edge(i16, &.{ 0, 3, 5, -1, 0x104 });
    slot_a.state = other;
    slot_b.state = other;
    v.g.D_800F1DC8().* = ctx.pick(u8, &.{ 0, 0x10, 0x0F, 0x1F, 0x80, 0xFF });

    const case = ctx.range(u8, 0, 9);
    if (case <= 3) {
        // The upload path: DAC is streamed and in state 4.
        slot_a.state = 4;
        v.g.D_800F1DAC().* = slot_a;
        v.g.D_800F1DB0().* = if (ctx.chance(2)) null else slot_b;
        v.g.D_800F1DD0().* = block;
    } else if (case <= 6) {
        // The free path: DAC not streamed, DB0 in state 4.
        v.g.D_800F1DAC().* = if (ctx.chance(2)) null else slot_a;
        slot_b.state = 4;
        v.g.D_800F1DB0().* = slot_b;
        v.g.D_800F1DD0().* = if (ctx.chance(2)) null else block;
    } else {
        // Nothing to do.
        v.g.D_800F1DAC().* = if (ctx.chance(2)) null else slot_a;
        v.g.D_800F1DB0().* = if (ctx.chance(2)) null else slot_b;
        v.g.D_800F1DD0().* = if (ctx.chance(2)) null else block;
    }
    return .{};
}

pub fn classify(_: Args) usize {
    const a = v.g.D_800F1DAC().*;
    if (a != null and a.?.state == 4) return 0;
    const b = v.g.D_800F1DB0().*;
    if (b != null and b.?.state == 4) {
        return if (v.g.D_800F1DD0().* == null) 2 else 1;
    }
    return 3;
}

pub const stubs = struct {
    pub fn vs_battle_parseTim(ctx: *zd.Ctx, buf: anytype, tim: anytype) void {
        _ = buf;
        const t: *v.TIM_IMAGE = @ptrCast(@alignCast(tim));
        t.mode = ctx.value(u32);
        t.crect = null;
        t.prect = rect;
        rect.x = ctx.value(i16);
        rect.y = ctx.value(i16);
        t.caddr = if (ctx.value(u8) < 128) clut else null;
        t.paddr = if (ctx.value(u8) < 200) img else null;
    }

    pub fn LoadImage(ctx: *zd.Ctx, r: anytype, p: anytype) c_int {
        _ = r;
        _ = p;
        return ctx.value(c_int);
    }

    pub fn vs_main_loadClut(ctx: *zd.Ctx, a: anytype, slot: anytype, off: anytype, count: anytype) void {
        _ = ctx;
        _ = a;
        _ = slot;
        _ = off;
        _ = count;
    }

    pub fn vs_main_freeCdQueueSlot(ctx: *zd.Ctx, slot: anytype) void {
        const s: *v.vs_main_CdQueueSlot = @ptrCast(@alignCast(slot));
        s.state = ctx.value(i16);
    }

    pub fn vs_main_freeHeapR(ctx: *zd.Ctx, p: anytype) void {
        if (p == null) return;
        const w: *u32 = @ptrCast(@alignCast(p));
        w.* = ctx.value(u32);
    }
};
