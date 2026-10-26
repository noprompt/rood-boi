//! zig_diff spec: func_80069FC4 -> func_80069FC4.func_80069FC4 (146C.c).
//! Inputs: an index 0-15 into vs_battle_actors (the table's room), with its
//! entry null or a random arena actor whose unk27 is 0x80 (the early return)
//! or an edge value (0, 1, 0x7F, 0x81, 0xFF: 0xFF wraps unk0 to 0). Its stats
//! block is random bytes, so every limb hp, the unk30 byte and the status word
//! are fresh values. arg1 covers zero, negatives, 255/256 and the i32 extremes
//! (stored truncated to unk1). func_800A0BE0's return has bit 24 forced on or
//! off by a flag prepare sets, its other bits random. func_800A1108 and
//! func_800A36E0 write the sp10 out-parameter the C reads back, and
//! func_800A36E0 does so only sometimes.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80069FC4));

pub const classes = [_][:0]const u8{ "null-actor", "unk27-0x80", "flag-set", "flag-clear" };

/// Set by prepare: whether func_800A0BE0 reports the 0x01000000 bit.
var hp_flag: bool = false;

pub const stubs = struct {
    pub fn func_800A0BE0(ctx: *zd.Ctx, id: anytype) c_uint {
        _ = id;
        const r = ctx.value(u32);
        return if (hp_flag) r | 0x0100_0000 else r & ~@as(u32, 0x0100_0000);
    }

    pub fn func_800E6694(ctx: *zd.Ctx, id: anytype) c_short {
        _ = id;
        return ctx.value(c_short);
    }

    pub fn func_800A1108(ctx: *zd.Ctx, id: anytype, out: anytype) c_int {
        _ = id;
        const o: *v.func_8006EBF8_t = @ptrCast(@alignCast(out));
        o.unk0.unk0.value = ctx.value(i32);
        return ctx.value(c_int);
    }

    pub fn func_800A36E0(ctx: *zd.Ctx, id: anytype, pos: anytype, out: anytype) void {
        _ = id;
        _ = pos;
        if (ctx.value(u1) == 1) {
            const o: *v.func_8006EBF8_t = @ptrCast(@alignCast(out));
            o.unk0.unk0.value = ctx.value(i32);
        }
    }

    pub fn func_80069EF0(ctx: *zd.Ctx, id: anytype) *v.func_80069EF0_t {
        _ = id;
        return ctx.alloc(v.func_80069EF0_t);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const idx = ctx.range(c_int, 0, 15);
    const arg1 = ctx.pick(c_int, &.{ 0, 1, -1, 255, 256, 0x7FFF_FFFF, -0x8000_0000 });
    const actor = ctx.alloc(v.vs_battle_actor);
    const stats = ctx.alloc(v.vs_battle_actor2);
    psx.put(&actor.stats, stats);
    actor.unk27 = if (ctx.chance(6)) 0x80 else ctx.pick(u8, &.{ 0, 1, 0x7F, 0x81, 0xFF });
    hp_flag = ctx.chance(2);
    const table = v.g.vs_battle_actors();
    table[@intCast(idx)] = if (ctx.chance(8)) null else actor;
    return .{ idx, arg1 };
}

pub fn classify(args: Args) usize {
    const entry = v.g.vs_battle_actors()[@intCast(args[0])];
    const actor = entry orelse return 0;
    if (actor.unk27 == 0x80) return 1;
    return if (hp_flag) 2 else 3;
}
