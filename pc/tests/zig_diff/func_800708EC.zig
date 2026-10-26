//! zig_diff spec: func_800708EC -> func_800708EC.func_800708EC (146C.c).
//! Inputs: the global D_800F19CC pointing at an arena object, the 16-entry
//! vs_battle_actors table set to arena actors that share one stats block, and
//! a selected entry of the 23-entry table (sometimes out of range, inside the
//! arena). The entry's unk9 covers 0..15, 16..127 (both sides of the 0x10 bit),
//! 128..255 (negative as a signed char, so `temp_v1 < 16` holds) and the edge
//! 16 itself. unkA is 0xFF (a lookup) a third of the time, never with unk9 >= 128
//! or unk9 == 16 (those would index past the table in the mutated copies). The
//! callee stub sometimes writes unk844 and always unk4.unk40.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800708EC));

pub const classes = [_][:0]const u8{ "lookup-limb", "given-limb", "callee", "far" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const stats = ctx.alloc(v.vs_battle_actor2);
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        psx.put(&actor.stats, stats);
        table[i] = actor;
    }
    // Allocated last: the out-of-range entry reads and writes run into free arena, not into the actors.
    const g = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = g;
    const arr: [*]v.D_800F19CC_t5 = @ptrCast(&g.unk29C0);
    g.unk298C = ctx.pick(u8, &.{ 0, 1, 22, 23, 64, 128, 255 });
    const e = &arr[g.unk298C];
    e.unk9 = ctx.pick(u8, &.{ 0, 1, 15, 16, 17, 31, 32, 64, 127, 128, 255 });
    // Negative as a signed char about one run in four: the signed/unsigned
    // reading of temp_v1 then differs.
    if (ctx.chance(4)) e.unk9 = ctx.range(u8, 128, 255);
    e.unkA = if (ctx.chance(3)) 255 else ctx.int(u8);
    // A lookup needs unk9 < 16: elsewhere unkA == 255 would index past the table
    // (unk9 == 16 is the edge the `<= 16` mutant reads as a lookup).
    if ((e.unk9 >= 128 or e.unk9 == 16) and e.unkA == 255) e.unkA = 0;
    g.unk8.unk4.unk40 = if (ctx.chance(2)) 0 else ctx.pick(i32, &.{ 1, -1, 4 });
    if (ctx.chance(3)) g.unk8.unk4.unk0.targetActor = e.unk9;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const s = v.g.D_800F19CC().*.?;
    const arr: [*]v.D_800F19CC_t5 = @ptrCast(&s.unk29C0);
    const e = &arr[s.unk298C];
    const temp: i8 = @bitCast(e.unk9);
    if (temp < 16) return if (e.unkA == 255) 0 else 1;
    if (s.unk8.unk4.unk40 == 0 and e.unk9 == s.unk8.unk4.unk0.targetActor) return 2;
    return 3;
}

pub const stubs = struct {
    pub fn func_8007087C(ctx: *zd.Ctx, p: anytype) void {
        const s: *v.D_800F19CC_t2 = @ptrCast(@alignCast(p));
        if (ctx.value(u1) == 1) s.unk844.vx = ctx.value(i16);
        s.unk4.unk40 = ctx.value(i32);
    }
};
