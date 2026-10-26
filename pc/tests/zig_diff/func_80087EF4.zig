//! zig_diff spec: func_80087EF4 -> func_80087EF4.func_80087EF4 (146C.c).
//! Inputs: one actor in the arena. Timer 5 usually fires, the other timers
//! fire sometimes, and statuses carries the drain (0x4000), regen (0x20000),
//! status-10 and random bits, or none. Limbs get hp and maxHp edges that
//! include 2 and the equal-to-maxHp case, the bitfield limb indices are 0,
//! in range, or 255 (the C reads past limbs inside the arena), unk957 is
//! sometimes 0, and the D_800E8204 mask table is sometimes 0. The rand stubs
//! return values prepare picks, aimed at the hp == 0, hp == currentHP,
//! currentHP == maxHP and limb hp == maxHp equalities the C compares.
//! func_80093B68 writes unk957 and limbs[0].hp, which the C reads back.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80087EF4));

pub const classes = [_][:0]const u8{ "drain", "regen", "status-10", "idle" };

var the_actor: ?*v.vs_battle_actor2 = null;
var rand_val: c_int = 0;
var smooth_val: c_int = 0;

pub const stubs = struct {
    pub fn vs_main_getRand(ctx: *zd.Ctx, n: anytype) c_int {
        _ = ctx;
        _ = n;
        return rand_val;
    }

    pub fn vs_main_getRandSmoothed(ctx: *zd.Ctx, n: anytype) c_int {
        _ = ctx;
        _ = n;
        return smooth_val;
    }

    pub fn func_80093B68(ctx: *zd.Ctx, arg0: anytype, arg1: anytype, arg2: anytype, arg3: anytype) void {
        _ = arg0;
        _ = arg1;
        _ = arg2;
        _ = arg3;
        const a = the_actor orelse return;
        // The C reads unk957 and limbs[0].hp back after this call.
        if (ctx.value(u2) == 0) a.unk957 = ctx.value(u8);
        if (ctx.value(u2) == 0) a.limbs[0].hp = ctx.value(i16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const a = ctx.alloc(v.vs_battle_actor2);
    the_actor = a;

    for (0..6) |k| a.statusTimers[k] = ctx.edge(u8, &.{ 0, 0, 1, 2, 255 });
    a.statusTimers[5] = ctx.edge(u8, &.{ 1, 1, 1, 0, 2 });

    a.statuses = if (ctx.chance(3)) 0 else ctx.int(i32);

    const tbl = v.g.D_800E8204();
    for (0..4) |i| tbl[i] = if (ctx.chance(3)) 0 else ctx.int(i32);

    psx.setBits(a, "unk34", ctx.edge(u8, &.{ 0, 0, 1, 2, 3, 5, 6, 255 }));
    psx.setBits(a, "unk35", ctx.edge(u8, &.{ 0, 1, 2, 4, 6, 255 }));

    a.unk957 = if (ctx.chance(2)) 0 else ctx.int(u8);

    a.currentHP = ctx.pick(i16, &.{ 0, 1, 19, 20, 100, -1, -20, 32767, -32768, 500 });
    a.maxHP = ctx.pick(i16, &.{ 0, 1, 19, 20, 100, 500, -1, 32767, -32768 });

    // Smoothed rand (regen branch): hp2 = maxHP/20 - 2 + smooth_val.
    const base: c_int = @divTrunc(@as(c_int, a.maxHP), 20) - 2;
    smooth_val = switch (ctx.range(u8, 0, 3)) {
        0 => (@as(c_int, a.maxHP) - @as(c_int, a.currentHP)) - base, // currentHP lands on maxHP
        1 => -base, // hp2 == 0
        2 => ctx.range(c_int, -40, 40),
        else => ctx.range(c_int, -300, 300),
    };
    const hp2: c_int = base + smooth_val;
    const delta: c_int = if (hp2 < 0) hp2 + 7 else hp2;
    const shift: c_int = delta >> 3;

    for (&a.limbs) |*limb| {
        limb.maxHp = ctx.edge(i16, &.{ 0, 0, 1, 50, 100, -1 });
        limb.hp = ctx.edge(i16, &.{ 2, 2, 0, 1, -1, 100, 32767 });
        // Equal to maxHp after the regen add: the limb's `<` sees equal sides.
        if (ctx.chance(3)) limb.hp = @truncate(@as(c_int, limb.maxHp) - shift);
    }

    // Drain branch: hp = currentHP/20 + rand.
    const cur: c_int = a.currentHP;
    rand_val = switch (ctx.range(u8, 0, 3)) {
        0 => -@divTrunc(cur, 20), // hp == 0
        1 => cur - @divTrunc(cur, 20), // hp == currentHP
        2 => ctx.range(c_int, -128, 127),
        else => ctx.range(c_int, -3, 3),
    };

    return .{a};
}

pub fn classify(args: Args) usize {
    const a = args[0].?;
    if (a.statusTimers[5] == 1) {
        if ((a.statuses & 0x4000) != 0) return 0;
        if ((a.statuses & 0x20000) != 0) return 1;
    }
    if ((a.statuses & 0x10) != 0) return 2;
    return 3;
}
