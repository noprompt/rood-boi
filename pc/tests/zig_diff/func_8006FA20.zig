//! zig_diff spec: func_8006FA20 -> func_8006FA20.func_8006FA20 (146C.c).
//! Inputs: the battle state record D_800F19CC (built in the arena and pointed to by
//! the global) with its action index 0 or 1-255, the action's unlocked bit either way,
//! and the three gates (unk40, unk2C07, targetActor) zero or not, so each failing
//! conjunct and the unlock path are reached. func_8006C39C may move the action index,
//! which the C reads back for the message and the unlock store. The unlock-query result
//! is any int, split into its two 16-bit halves. Not covered: an action index with bit 15
//! set would index vs_main_actions far past its 256 entries, so the index stays in range.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006FA20));

pub const classes = [_][:0]const u8{ "index-zero", "already-unlocked", "unk40-set", "busy", "target-set", "unlock" };

pub const stubs = struct {
    /// Moves the battle's action index in about half the calls (the C reads it back).
    pub fn func_8006C39C(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) {
            v.g.D_800F19CC().*.?.unk8.actionIndex = ctx.value(u8);
        }
    }
    /// Assumed external: the unlock query's result, any bits (the C prototype returns int).
    pub fn _isArtOrAbilityUnlocked(ctx: *zd.Ctx) c_int {
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = d;
    d.unk8.actionIndex = if (ctx.chance(4)) 0 else ctx.range(u16, 1, 255);
    const idx = d.unk8.actionIndex;
    psx.setBits(&v.g.actions()[idx], "unlocked", ctx.int(u1));
    d.unk8.unk4.unk40 = if (ctx.chance(2)) 0 else ctx.pick(i32, &.{ -1, 1, std.math.maxInt(i32), std.math.minInt(i32) });
    d.unk2C07 = if (ctx.chance(2)) 0 else ctx.pick(u8, &.{ 1, 0x80, 0xFF });
    d.unk8.unk4.unk0.targetActor = if (ctx.chance(2)) 0 else ctx.pick(u8, &.{ 1, 0x80, 0xFF });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F19CC().*.?;
    if (d.unk8.actionIndex == 0) return 0;
    if (psx.getBits(&v.g.actions()[d.unk8.actionIndex], "unlocked") != 0) return 1;
    if (d.unk8.unk4.unk40 != 0) return 2;
    if (d.unk2C07 != 0) return 3;
    if (d.unk8.unk4.unk0.targetActor != 0) return 4;
    return 5;
}
