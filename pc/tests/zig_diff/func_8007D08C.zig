//! zig_diff spec: func_8007D08C -> func_8007D08C.func_8007D08C (146C.c).
//! The inputs: arg0 is a table index in 0..15 (the C reads vs_battle_actors[arg0]
//! and the table has 16 entries; prepare sets all 16, each NULL or a fresh arena
//! actor with a random allegiance and unk8 drawn from {0x20, 0, 0x1F, 0x21, 0xA0}).
//! arg1 is zero, one, minus one, INT_MIN, 0x20 or 0x40, so both sides of `arg1 != 0`
//! and both signs of a nonzero value are taken. The two func_80095B7C calls are
//! stubs that write the actor's unk8 and allegiance (the field the C calls unk1C)
//! and sometimes clear the table entry, so the port must store before it calls.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007D08C));

pub const classes = [_][:0]const u8{
    "arg1-nonzero-null",
    "arg1-nonzero-unk8-20",
    "arg1-nonzero-other",
    "arg1-zero-null",
    "arg1-zero-actor",
};

pub const stubs = struct {
    pub fn func_80095B7C(ctx: *zd.Ctx, a: anytype, b: anytype) void {
        _ = b;
        const idx: usize = @intCast(a);
        const p = v.g.vs_battle_actors()[idx] orelse return;
        if (ctx.value(u1) == 1) p.unk8 = ctx.value(u8);
        if (ctx.value(u1) == 1) p.allegiance = ctx.value(u16);
        if (ctx.value(u3) == 0) v.g.vs_battle_actors()[idx] = null;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const table = v.g.vs_battle_actors();
    for (0..16) |i| {
        if (ctx.chance(4)) {
            table[i] = null;
            continue;
        }
        const a = ctx.alloc(v.vs_battle_actor);
        a.unk8 = ctx.edge(u8, &.{ 0x20, 0x20, 0, 0x1F, 0x21, 0xA0 });
        a.allegiance = ctx.int(u16);
        table[i] = a;
    }
    const arg0 = ctx.range(c_int, 0, 15);
    const arg1 = ctx.pick(c_int, &.{ 0, 1, -1, std.math.minInt(c_int), 0x20, 0x40 });
    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    const table = v.g.vs_battle_actors();
    const p = table[@intCast(args[0])];
    if (args[1] != 0) {
        const a = p orelse return 0;
        return if (a.unk8 == 0x20) 1 else 2;
    }
    return if (p == null) 3 else 4;
}
