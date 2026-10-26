//! zig_diff spec: func_80088B8C -> func_80088B8C.func_80088B8C (146C.c).
//! Inputs: the camera gate (D_800F196C == 2 and _cameraMode in 1..3, with 0,
//! 4 and 5 and random values for the failing cases), the tick counter
//! D_800E8498 at 0 or -40..40 and the game tick speed near the i32 limits
//! without overflowing the sum, a D_800F19CC block in the arena whose
//! targetActor is 0 or 1..15 (the 16-entry actor table, every entry set), a
//! target stats block with bit 3 of statuses set or clear (any sign), an
//! unk40 of 0, 1 or -1, and a character's risk at 0, 99, 100, 101, 255 or
//! 65535. The C calls nothing, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80088B8C));

pub const classes = [_][:0]const u8{ "camera-off", "gate-off", "other-target", "risk-capped", "risk-bumped" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const st = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = st;
    st.unk8.unk4.unk0.targetActor = if (ctx.chance(3)) 0 else ctx.range(u8, 0, 15);
    st.unk8.unk4.unk40 = ctx.pick(i32, &.{ 0, 1, -1 });

    v.g.D_800F196C().* = if (ctx.chance(10)) ctx.int(u32) else 2;
    v.g._cameraMode().* = if (ctx.chance(10)) ctx.int(u32) else ctx.edge(u32, &.{ 0, 1, 2, 3, 4, 5 });
    v.g.D_800E8498().* = if (ctx.chance(2)) 0 else ctx.range(i32, -40, 40);
    v.g.vs_gametime_tickspeed().* = if (ctx.chance(2))
        ctx.edge(i32, &.{ 0, 1, 2, 7, 30, 31, -1, 2147483600, -2147483600 })
    else
        ctx.range(i32, -2147483600, 2147483600);

    const tstats = ctx.alloc(v.vs_battle_actor2);
    tstats.statuses = if (ctx.chance(2)) ctx.int(i32) | 8 else ctx.int(i32) & ~@as(i32, 8);

    const pstats = ctx.alloc(v.vs_battle_actor2);
    pstats.risk = ctx.pick(u16, &.{ 0, 99, 100, 101, 255, 0xFFFF });
    const player = ctx.alloc(v.vs_battle_actor);
    psx.put(&player.stats, pstats);
    v.g.vs_battle_characterState().* = player;

    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        const a = ctx.alloc(v.vs_battle_actor);
        psx.put(&a.stats, tstats);
        table[i] = a;
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const cam_ok = v.g.D_800F196C().* == 2 and v.g._cameraMode().* < 4 and v.g._cameraMode().* != 0;
    if (!cam_ok) return 0;
    const st = v.g.D_800F19CC().*.?;
    const t = st.unk8.unk4.unk0.targetActor;
    const actor = v.g.vs_battle_actors()[t].?;
    const stats = psx.get(actor.stats).?;
    const gate = v.g.D_800E8498().* == 0 and (stats.statuses & 8) != 0 and st.unk8.unk4.unk40 == 0;
    if (!gate) return 1;
    if (t != 0) return 2;
    const risk = psx.get(v.g.vs_battle_characterState().*.?.stats).?.risk;
    return if (risk >= 100) 3 else 4;
}
