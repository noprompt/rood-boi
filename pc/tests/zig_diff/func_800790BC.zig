//! zig_diff spec: func_800790BC -> func_800790BC.func_800790BC (146C.c).
//! Inputs: a D_800F19CC_t in the arena, set as the global pointer, with a
//! count of 1-6 (never 0: the C then reads an uninitialised var_s3), four
//! stat blocks of 0-30 entries (unk4A), and random unk40 flags (zero half the
//! time) and target actors (zero about a third of the time, so the final
//! `targetActor != 0` check goes both ways and the C's second pass reaches
//! its result). func_8009E4B0 returns 0 (the EQUAL edge of `+ 1 > 1`), the
//! wrap values 0xFFFFFFFF and 0xFFFFFFFE, 1, or any u32, and may write an
//! entry's unk40 that the C reads later. func_80074A20 returns 0, -1, 1 or
//! any c_int (so negative results reach the second pass), and may rewrite a
//! target actor or unk40 that the final checks read back.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800790BC));

pub const classes = [_][:0]const u8{ "no-active", "active-unk4-zero", "active-unk4-set" };

fn targetActor(ctx: *zd.Ctx) u8 {
    return if (ctx.chance(3)) 0 else ctx.int(u8);
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = d;
    d.unk4 = ctx.range(u32, 1, 6);
    for (&d.unk854) |*e| {
        e.unk4A = if (ctx.chance(6)) 0 else ctx.range(u16, 0, 30);
        e.unk4.unk40 = if (ctx.chance(2)) 0 else ctx.int(i32);
        e.unk4.unk0.targetActor = targetActor(ctx);
        for (&e.unk4C) |*entry| {
            entry.unk40 = if (ctx.chance(2)) 0 else ctx.int(i32);
            entry.unk0.targetActor = targetActor(ctx);
        }
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F19CC().*.?;
    var active = false;
    var k: u32 = 0;
    while (k < d.unk4) : (k += 1) {
        const e = &d.unk854[k % 4];
        var j: u32 = 0;
        while (j < e.unk4A) : (j += 1) {
            if (e.unk4C[j].unk40 == 0) active = true;
        }
    }
    if (!active) return 0;
    return if (d.unk854[0].unk4.unk40 == 0) 1 else 2;
}

pub const stubs = struct {
    pub fn func_8009E4B0(ctx: *zd.Ctx, id: anytype) c_uint {
        _ = id;
        const x = ctx.value(u8);
        if (ctx.value(u8) < 48) {
            const d = v.g.D_800F19CC().*.?;
            d.unk854[0].unk4C[ctx.value(u8) % 30].unk40 = ctx.value(i32);
        }
        if (x < 40) return 0;
        if (x < 80) return 0xFFFF_FFFF;
        if (x < 110) return 0xFFFF_FFFE;
        if (x < 140) return 1;
        return ctx.value(c_uint);
    }

    pub fn func_80074A20(ctx: *zd.Ctx, arg0: anytype) c_int {
        _ = arg0;
        const x = ctx.value(u8);
        if (ctx.value(u8) < 64) {
            const d = v.g.D_800F19CC().*.?;
            d.unk854[ctx.value(u8) % 4].unk4.unk0.targetActor = ctx.value(u8);
        }
        if (ctx.value(u8) < 48) {
            const d = v.g.D_800F19CC().*.?;
            d.unk854[ctx.value(u8) % 4].unk4.unk40 = ctx.value(i32);
        }
        if (x < 60) return 0;
        if (x < 100) return -1;
        if (x < 140) return 1;
        return ctx.value(c_int);
    }
};
