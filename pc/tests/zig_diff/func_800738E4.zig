//! zig_diff spec: func_800738E4 -> func_800738E4.func_800738E4 (146C.c).
//! Inputs: the 16-entry vs_battle_actors table (null, or an actor whose unk8 is
//! 0x10, 0x11, 0x40 or 0), D_80050468.unk0 zero or not, D_800F18AC (0, 1..5, -1),
//! and vs_main_soundData.unk4 at 0xFFFF, at the unk14 slot D_800F18AC selects,
//! at the slot D_800F18AC == 0 would read (unk14[-1]), or random. The mode picked
//! in prepare decides whether the first or second func_800BEC58 call returns 1,
//! which takes the early return. The stub for func_800BEC58 may also write
//! unk4, as a real callee could.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800738E4));

pub const classes = [_][:0]const u8{
    "early-return-0xA",
    "early-return-0x10",
    "sound-ffff",
    "sound-match",
    "sound-zero-match",
    "sound-other",
};

/// Which early-return path this run takes (0 none, 1 first call, 2 second call).
var mode: u8 = 0;

pub const stubs = struct {
    pub fn func_800BEC58(ctx: *zd.Ctx, id: anytype, a: anytype, b: anytype, c: anytype) c_short {
        _ = a;
        _ = b;
        _ = c;
        if (id == 0xA and mode == 1) return 1;
        if (id == 0x10 and mode == 2) return 1;
        if (ctx.value(u8) < 30) v.g.vs_main_soundData().unk4 = ctx.value(u32);
        // Never 1 (bit 1 is set): the C takes the non-early path.
        return @as(c_short, ctx.value(u8) | 2);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    mode = ctx.edge(u8, &.{ 0, 0, 0, 1, 2 });

    const dl = v.g.D_80050468();
    dl.unk0 = if (mode == 2)
        ctx.edge(u8, &.{ 1, 0x80, 0xFF })
    else
        ctx.edge(u8, &.{ 0, 1, 0x80, 0xFF });

    const tbl = v.g.vs_battle_actors();
    for (0..16) |i| {
        if (ctx.chance(5)) {
            tbl[i] = null;
            continue;
        }
        const a = ctx.alloc(v.vs_battle_actor);
        a.unk8 = ctx.edge(u8, &.{ 0x10, 0x10, 0x11, 0x40, 0 });
        tbl[i] = a;
    }

    const s = v.g.vs_main_soundData();
    const d = ctx.edge(i32, &.{ 0, 1, 2, 3, 4, 5, -1 });
    v.g.D_800F18AC().* = d;
    s.unk4 = ctx.pick(u32, &.{ 0xFFFF, 0xFFFF, 0xFFFE, 0 });
    if (d >= 1 and d <= 4 and ctx.chance(2)) {
        psx.byteAt(u32, &s.unk14, (@as(isize, d) - 1) * 4).* = s.unk4;
    }
    if (d == 0 and ctx.chance(2)) {
        s.unk4 = psx.byteAt(u32, &s.unk14, -4).*;
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if (mode == 1) return 0;
    if (mode == 2) return 1;
    const s = v.g.vs_main_soundData();
    if (s.unk4 == 0xFFFF) return 2;
    const d = v.g.D_800F18AC().*;
    if (d != 0 and s.unk4 == psx.byteAt(u32, &s.unk14, (@as(isize, d) - 1) * 4).*) return 3;
    if (d == 0 and s.unk4 == psx.byteAt(u32, &s.unk14, -4).*) return 4;
    return 5;
}
