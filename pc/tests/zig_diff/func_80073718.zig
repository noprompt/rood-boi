//! zig_diff spec: func_80073718 -> func_80073718.func_80073718 (146C.c).
//! Inputs: a character state (weaponDrawn any i32), a camera whose pitch sits
//! on the /512 and sign edges (-1, -511..-513, 512, the i32 extremes) and
//! whose initialDistance is 0x600 half the time, and the 16-slot actor table
//! with no actors, some, or all of them present. Present actors start with
//! unk8 at the switch's cases (0x10, 0x20, 0x40, 0x80), 0 and other values.
//! The func_8009FC60 stub rewrites unk8 (and sometimes a table slot) as the
//! real callee can and returns an int; the func_800E6700 stub rewrites
//! another slot's unk8.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80073718));

pub const classes = [_][:0]const u8{ "no-actors", "some-actors", "all-actors" };

/// Arena actors for the table: the stubs may move one into a slot.
var pool: [16]*v.vs_battle_actor = undefined;

pub const stubs = struct {
    pub fn func_8009FC60(ctx: *zd.Ctx, id: anytype, a: anytype, b: anytype, c: anytype) c_int {
        _ = a;
        _ = b;
        _ = c;
        const idx: usize = @intCast(id);
        if (ctx.value(u8) % 4 == 0) v.g.vs_battle_actors()[idx] = pool[ctx.value(u8) % 16];
        const actor = v.g.vs_battle_actors()[idx] orelse return ctx.value(c_int);
        if (ctx.value(u1) == 1) {
            actor.unk8 = switch (ctx.value(u8) % 6) {
                0 => 0x10,
                1 => 0x20,
                2 => 0x40,
                3 => 0x80,
                else => ctx.value(u8),
            };
        }
        return ctx.value(c_int);
    }

    pub fn func_800E6700(ctx: *zd.Ctx, id: anytype) void {
        _ = id;
        if (ctx.value(u1) == 1) {
            const other = v.g.vs_battle_actors()[ctx.value(u8) % 16] orelse return;
            other.unk8 = ctx.value(u8);
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const ch = ctx.alloc(v.vs_battle_actor);
    ch.weaponDrawn = ctx.int(i32);
    v.g.vs_battle_characterState().* = ch;

    const cam = v.g.vs_battle_cameraCurrentSpherical();
    cam.delta.pitch = ctx.pick(i32, &.{ 0, 511, 512, -1, -511, -512, -513, 0x7FFF_FFFF, -0x8000_0000 });
    cam.initialDistance = if (ctx.chance(2)) 0x600 else ctx.pick(i32, &.{ 0x5FF, 0x601, 0, -1 });

    const mode = ctx.range(u8, 0, 2);
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        const actor = ctx.alloc(v.vs_battle_actor);
        actor.unk8 = ctx.pick(u8, &.{ 0x10, 0x20, 0x40, 0x80, 0, 0x11, 0xFF });
        pool[i] = actor;
        const present = switch (mode) {
            0 => false,
            2 => true,
            else => ctx.chance(2),
        };
        table[i] = if (present) actor else null;
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const table = v.g.vs_battle_actors();
    var n: usize = 0;
    for (0..16) |i| {
        if (table[i] != null) n += 1;
    }
    if (n == 0) return 0;
    return if (n == 16) 2 else 1;
}
