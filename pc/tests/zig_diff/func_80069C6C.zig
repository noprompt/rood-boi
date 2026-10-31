//! zig_diff spec: func_80069C6C -> func_80069C6C.func_80069C6C (146C.c).
//! Inputs: arg0 zero, negative, positive and INT_MIN; a D_800F19CC object in the
//! arena whose unk0 selects one of the four unk854 slots (any u32, so the mask
//! and its high bits are exercised); the slot's targetActor zero or not (with
//! the 0x80 and 0xFF bit patterns); the battle-ability target window zero or
//! busy; the timer near the u16 edges; tickspeed at the i32 edges so that
//! tickspeed * 2 wraps. The stub of func_80078828 returns zero or any c_int,
//! and writes the timer, the tickspeed and the window, which the C reads back.
//! The `switch (targetActor != 0)` case 0 is unreachable: the early return
//! above it already requires targetActor != 0, and nothing (no store, no call)
//! runs between the two reads, so the switch always sees 1. That branch is
//! waived in specs.toml.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80069C6C));

pub const classes = [_][:0]const u8{ "arg-nonzero", "no-target", "window-busy", "window-free" };

pub const stubs = struct {
    pub fn func_80078828(ctx: *zd.Ctx, x: anytype) c_int {
        _ = x;
        const d = v.g.D_800F19CC().*.?;
        if (ctx.value(u1) == 1) d.battleAbilityTimer = ctx.value(u16);
        if (ctx.value(u2) == 0) v.g.vs_gametime_tickspeed().* = ctx.value(i32);
        if (ctx.value(u1) == 1) d.battleAbilityTargetWindow = ctx.value(u16);
        const r = ctx.value(c_int);
        return if (ctx.value(u2) == 0) 0 else r;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = d;
    d.unk0 = ctx.pick(u32, &.{ 0, 1, 2, 3, 4, 0xFFFF_FFFF, 0x8000_0000 });
    const ta: u8 = if (ctx.chance(3)) 0 else ctx.pick(u8, &.{ 1, 0x80, 0xFF });
    d.unk854[d.unk0 & 3].unk4.unk0.targetActor = ta;
    d.battleAbilityTargetWindow = if (ctx.chance(2)) 0 else ctx.pick(u16, &.{ 1, 0x8000, 0xFFFF });
    d.battleAbilityTimer = ctx.pick(u16, &.{ 0, 0xFFFF, 0x8000, 0x7FFF });
    v.g.vs_gametime_tickspeed().* = ctx.pick(i32, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000, 0x4000_0000, -0x4000_0000 });
    const arg: c_int = ctx.pick(c_int, &.{ 0, 0, 1, -1, std.math.minInt(c_int) });
    return .{arg};
}

pub fn classify(args: Args) usize {
    if (args[0] != 0) return 0;
    const d = v.g.D_800F19CC().*.?;
    if (d.unk854[d.unk0 & 3].unk4.unk0.targetActor == 0) return 1;
    if (d.battleAbilityTargetWindow != 0) return 2;
    return 3;
}
