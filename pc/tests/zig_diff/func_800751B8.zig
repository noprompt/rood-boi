//! zig_diff spec: func_800751B8 -> func_800751B8.func_800751B8 (146C.c).
//! Inputs: an actor in vs_battle_actors (slot 0-15) with a stats block, a
//! room-section argument whose vy is often exactly 17 (the >= edge, signed,
//! with negatives), D_800F196C equal to 3 one time in three, and a screen
//! transition step that is 0 most of the time. The word func_800A0BE0 returns
//! has its 0x70000, 0x16704000 and 0x504000 bits cleared in turns, so each
//! path (room section lookup, the return-3 path, the store guard) runs. The
//! room lookup is null or a section whose unk6 is 0x10 or not; the flags
//! unk0_16/unk0_17 are random; the final call returns 1 or another value.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800751B8));

pub const classes = [_][:0]const u8{ "transition-busy", "state-3", "vy-equal-17", "vy-below-17", "vy-above-17" };

pub const stubs = struct {
    pub fn func_800A0BE0(ctx: *zd.Ctx, arg0: anytype) c_uint {
        _ = arg0;
        var r = ctx.value(c_uint);
        const m = ctx.value(u8);
        if (m < 96) r &= ~@as(c_uint, 0x70000); // temp_a2 == 0: arguments come from arg1
        if (m >= 128 and m < 176) r &= ~@as(c_uint, 0x16704000); // the return-3 path can run
        if (m >= 176 and m < 208) r &= ~@as(c_uint, 0x504000); // the value store runs
        return r;
    }

    pub fn func_8008B764(ctx: *zd.Ctx, arg0: anytype, arg1: anytype, arg2: anytype) *v._mpdRoomSection3 {
        _ = arg0;
        _ = arg1;
        _ = arg2;
        const s = ctx.alloc(v._mpdRoomSection3);
        psx.setBits(s, "unk0_16", ctx.value(u1));
        psx.setBits(s, "unk0_17", ctx.value(u1));
        return s;
    }

    pub fn func_8008D438(ctx: *zd.Ctx, arg0: anytype, arg1: anytype, arg2: anytype) ?*v._mpdRoomSection9 {
        _ = arg0;
        _ = arg1;
        _ = arg2;
        if (ctx.value(u8) < 96) return null; // the C's NULL test
        const s = ctx.alloc(v._mpdRoomSection9);
        s.unk6 = if (ctx.value(u1) == 1) 0x10 else ctx.value(i16);
        return s;
    }

    pub fn func_80073F7C(ctx: *zd.Ctx, sec: anytype, obj: anytype, slot: anytype) void {
        _ = sec;
        _ = slot;
        const f: *v.func_8006EBF8_t3 = @ptrCast(@alignCast(obj));
        // The C reads the value back after this call.
        if (ctx.value(u2) != 0) f.unk0.value = ctx.value(i32);
        if (ctx.value(u2) == 0) v.g.D_800F196C().* = ctx.value(u32);
    }

    pub fn func_800792E4(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) c_int {
        _ = a;
        _ = b;
        _ = c;
        if (ctx.value(u1) == 1) v.g.vs_battle_screenTransitionStep().* = ctx.value(u32);
        return ctx.value(c_int);
    }

    pub fn func_800BEC58(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype, d: anytype) c_short {
        _ = a;
        _ = b;
        _ = c;
        _ = d;
        if (ctx.value(u2) == 0) return 1; // the C's == 1 test
        return ctx.value(c_short);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    const f = ctx.alloc(v.func_8006EBF8_t3);

    const slot: usize = @intCast(ctx.range(u8, 0, 15));
    const arg0: c_int = @intCast(slot);
    v.g.vs_battle_actors()[slot] = actor;
    psx.put(&actor.stats, stats);

    f.unk0.value = ctx.int(i32);
    f.unk4.vy = ctx.pick(i16, &.{ 17, 17, 16, 18, -1, 0, 32767, -32768 });

    // The 24-bit compare is equal about a third of the time; the byte the
    // C compares with temp_s3 is 0 or 1 half the time, so both sides meet.
    const top: u32 = @as(u32, ctx.int(u8)) << 24;
    actor.unk2C.s32 = if (ctx.chance(3))
        @as(i32, @bitCast((@as(u32, @bitCast(f.unk0.value)) & 0xFF_FFFF) | top))
    else
        ctx.int(i32);
    actor.unk2C.u8[3] = ctx.pick(u8, &.{ 0, 1 });

    v.g.D_800F196C().* = if (ctx.chance(3)) 3 else ctx.pick(u32, &.{ 0, 1, 2, 4, 0xFFFF_FFFF });
    v.g.vs_battle_screenTransitionStep().* = if (ctx.chance(5)) ctx.pick(u32, &.{ 1, 2, 0xFFFF_FFFF }) else 0;

    return .{ arg0, f };
}

pub fn classify(args: Args) usize {
    if (v.g.vs_battle_screenTransitionStep().* != 0) return 0;
    if (v.g.D_800F196C().* == 3) return 1;
    const vy = args[1].?.unk4.vy;
    if (vy == 17) return 2;
    return if (vy < 17) 3 else 4;
}
