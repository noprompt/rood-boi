//! zig_diff spec: func_80078364 -> func_80078364.func_80078364 (146C.c).
//! Inputs: the battle state object D_800F19CC_t from the arena, with the
//! action countdown (unk2984), the target actor (u8, with and without the
//! sign bit), the tick counter at 0x1E/0x1F/0xFF, the byte the step callee
//! writes back (unk298D, 0xFF or not), the step callee's return value (zero,
//! positive, negative, minimum), and vs_main_actions[actionIndex].unk2_4
//! selecting a D_800E8184 entry that is zero or nonzero. Both the step
//! result and the byte it writes are chosen in prepare and read by the stub,
//! so classify can name the path the C takes.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80078364));

pub const classes = [_][:0]const u8{
    "no-action",
    "target-tick-hit",
    "target-tick",
    "no-step",
    "step-not-done",
    "step-done-action",
    "step-done-cleanup",
};

/// What func_800C58F8 returns in this iteration (set by prepare).
var step_ret: c_int = 0;
/// The byte func_800C58F8 writes through its pointer (set by prepare).
var step_byte: u8 = 0;

pub const stubs = struct {
    pub fn func_800C58F8(ctx: *zd.Ctx, p: anytype) c_int {
        _ = ctx;
        const b: *u8 = @ptrCast(@alignCast(p));
        b.* = step_byte; // re-read by the C as unk298C
        return step_ret;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = d;

    d.unk2984 = if (ctx.chance(4)) 0 else ctx.edge(i32, &.{ 1, -1, 0x7FFF_FFFF, std.math.minInt(i32) });
    d.unk8.unk4.unk0.targetActor = if (ctx.chance(3)) 0 else ctx.edge(u8, &.{ 1, 0x7F, 0x80, 0xFF });
    d.unk298E = ctx.edge(u8, &.{ 0x1D, 0x1E, 0x1E, 0x1F, 0xFE, 0xFF });
    d.unk298C = ctx.int(u8);
    d.unk298D = ctx.int(u8);
    d.unk8.actionIndex = ctx.range(u16, 0, 255);
    psx.setBits(&v.g.actions()[d.unk8.actionIndex], "unk2_4", ctx.range(u4, 0, 15));

    const table = v.g.D_800E8184();
    for (0..16) |i| table[i] = ctx.edge(u8, &.{ 0, 1, 0x7F, 0x80, 0xFF });

    step_ret = if (ctx.chance(4)) 0 else ctx.edge(c_int, &.{ 1, -1, 0x4000_0000, std.math.minInt(c_int) });
    step_byte = if (ctx.chance(3)) 0xFF else ctx.edge(u8, &.{ 0, 1, 0x7F, 0x80, 0xFE });

    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F19CC().*.?;
    if (d.unk2984 == 0) return 0;
    if (d.unk8.unk4.unk0.targetActor != 0) return if (d.unk298E == 0x1E) 1 else 2;
    if (step_ret == 0) return 3;
    if (step_byte != 0xFF) return 4;
    const table = v.g.D_800E8184();
    const k = psx.getBits(&v.g.actions()[d.unk8.actionIndex], "unk2_4");
    return if (table[k] != 0) 5 else 6;
}
