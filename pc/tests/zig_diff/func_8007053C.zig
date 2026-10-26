//! zig_diff spec: func_8007053C -> func_8007053C.func_8007053C (146C.c).
//! Inputs: a D_800F19CC_t in the arena (pointed to by the global), with a
//! random or zero pad (the pad branch), an action index 0-255 whose unk2_0
//! bit is random, a kill-entry count of 0-23 (the loop's exit compare sees
//! equal sides every time it ends), entries whose enemy index is 0-15 (the
//! vs_battle_actors table), and random flag bytes in D_800E81C4 (some zero).
//! The callees are modelled: func_800C06E0 may rewrite pad, actionIndex or
//! the count; func_800C0700 fills its block; func_800C1564 returns 0 or 1;
//! func_8008631C fills its out-parameter; func_8006F630 rewrites its entry;
//! vs_main_memcpy really copies.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007053C));

pub const classes = [_][:0]const u8{ "pad-set", "no-entries", "entries" };

fn bytesOf(p: anytype) [*]u8 {
    const q: *anyopaque = if (@typeInfo(@TypeOf(p)) == .optional) p.? else p;
    return @ptrCast(q);
}

fn asPtr(comptime T: type, p: anytype) *T {
    const q: *anyopaque = if (@typeInfo(@TypeOf(p)) == .optional) p.? else p;
    return @ptrCast(@alignCast(q));
}

pub const stubs = struct {
    pub fn func_800C06E0(ctx: *zd.Ctx) void {
        const d = v.g.D_800F19CC().*.?;
        switch (ctx.value(u2)) {
            0 => {},
            1 => {
                d.unk2990.pad = ctx.value(i16);
            },
            2 => {
                d.unk8.actionIndex = ctx.value(u8);
            },
            3 => {
                d.unk2C00 = @as(u16, ctx.value(u8) % 24);
            },
        }
    }

    pub fn func_800C0700(ctx: *zd.Ctx, p: anytype) void {
        const b = asPtr([8]u8, p);
        for (b) |*x| x.* = ctx.value(u8);
    }

    pub fn func_800C1564(ctx: *zd.Ctx, a: anytype, b: anytype) c_int {
        _ = a;
        _ = b;
        return @as(c_int, ctx.value(u1));
    }

    pub fn func_8008631C(ctx: *zd.Ctx, action: anytype, target: anytype, unit: anytype, sub: anytype, out: anytype) c_int {
        _ = action;
        _ = target;
        _ = unit;
        _ = sub;
        const r = asPtr(v.D_800F19CC_t2, out);
        r.actionIndex = ctx.value(u16);
        r.unk4C[0].unk0.hp = ctx.value(i16);
        return ctx.value(c_int);
    }

    pub fn func_8006F630(ctx: *zd.Ctx, entry: anytype, res: anytype, sub: anytype) void {
        _ = res;
        _ = sub;
        const e = asPtr(v.D_800F19CC_t5, entry);
        e.unkE = ctx.value(i16);
        e.unk10 = ctx.value(i32);
    }

    pub fn vs_main_memcpy(ctx: *zd.Ctx, dest: anytype, src: anytype, sz: anytype) void {
        _ = ctx;
        const n: usize = sz;
        std.mem.copyForwards(u8, bytesOf(dest)[0..n], bytesOf(src)[0..n]);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = d;

    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    psx.put(&actor.stats, stats);
    for (0..16) |k| v.g.vs_battle_actors()[k] = actor;

    d.unk2998.pad = ctx.pick(i16, &.{ 0, 1, -1, -32768, 0x7fff });
    d.unk8.actionIndex = ctx.range(u16, 0, 255);
    d.unk2C00 = ctx.edge(u16, &.{ 0, 1, 2, 5, 23 });
    for (0..23) |k| d.unk29C0[k].unk9 = ctx.range(u8, 0, 15);
    for (0..16) |k| v.g.D_800E81C4()[k] = if (ctx.chance(2)) 0 else ctx.int(u8);

    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F19CC().*.?;
    if (d.unk2998.pad != 0) return 0;
    if (d.unk2C00 == 0) return 1;
    return 2;
}
