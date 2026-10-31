//! zig_diff spec: func_800C58F8 -> func_800C58F8.func_800C58F8 (5BF94.c).
//! Inputs: the target byte (null in about 4% of runs), the state D_800EABAA
//! in every range (0 runs the init path, 1-15 the row walk, 16-21 the switch
//! cases, 22-255 the fall-out), and the state object D_800EB9B8 with 256
//! text entries (unk9 kinds across the blocker, actor and string cases), two
//! rows of distinct indices, short counts, random button bits and a unk2D
//! that is often an entry of row 0 or row 1 (at the row's count, at 0, or
//! inside it), so the row walks, the clamps and their equal-bound cases run.
//! Callees: func_800C553C and func_800C56C0 write what the C reads back
//! (unk2C, unk0.unk1); func_800C5798 returns a valid item and writes a
//! unk990 entry; func_800C1D84 returns zero about half the time.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800C58F8));

pub const classes = [_][:0]const u8{
    "null-target", "state-0-init", "state-1-15-rows", "state-16", "state-17",
    "state-18",    "state-19",     "state-20",         "state-21",  "state-other",
};

const kinds = [_]u8{ 0, 1, 2, 5, 7, 15, 16, 31, 32, 0x80 };
// The state object: unk990 ends at 0x990 + 24 * 16, and the 0x4A54 text
// buffer is only pointer arithmetic past the object.
const obj_size = 0x4A54 + 256;

var g_obj: *v.func_800C56C0_t = undefined;
var g_item: *v.func_800C56C0_t2 = undefined;

pub const stubs = struct {
    pub fn func_800C553C(ctx: *zd.Ctx) void {
        // The C reads unk2C right after this call.
        if (ctx.value(u1) == 1) g_obj.unk2C = if (ctx.value(u1) == 1) 0 else ctx.value(u8) | 1;
    }

    pub fn func_800C56C0(ctx: *zd.Ctx) void {
        // The C reads unk0.unk1 after this call (state 19, the 0x40 path).
        if (ctx.value(u1) == 1) g_obj.unk0.unk1 = ctx.value(u8);
    }

    pub fn func_800C5798(ctx: *zd.Ctx, i: anytype, row: anytype, idx: anytype) ?*v.func_800C56C0_t2 {
        _ = i;
        _ = row;
        _ = idx;
        // The C reads unk990[prev].unk7 after this call.
        if (ctx.value(u2) == 0) g_obj.unk990[@as(usize, ctx.value(u8) % 24)].unk7 = ctx.value(u8);
        return g_item;
    }

    pub fn func_800C1D84(ctx: *zd.Ctx) c_int {
        if (ctx.value(u1) == 1) return 0;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    g_obj = @ptrCast(@alignCast(ctx.allocBytes(obj_size, 16)));
    v.g.D_800EB9B8().* = g_obj;
    g_item = ctx.alloc(v.func_800C56C0_t2);

    g_obj.unk2C = ctx.pick(u8, &.{ 0, 1 });
    g_obj.unk0.unk1 = ctx.edge(u8, &.{ 1, 2, 3 });
    for (0..24) |k| g_obj.unk990[k].unk1[2] = ctx.pick(u8, &.{ 0x21, 0x22 });

    // 256 text entries: unk40 is indexed by unk2D (any u8) and by the row tables.
    const ents: [*]v.func_800C5798_t = @ptrCast(@alignCast(ctx.allocBytes(256 * @sizeOf(v.func_800C5798_t), 16)));
    for (0..256) |k| {
        const e = &ents[k];
        e.unk9 = ctx.edge(u8, &kinds);
        e.unk8 = if (ctx.chance(3)) 16 else ctx.range(u8, 0, 141);
        e.unkB = ctx.edge(u8, &.{ 0x3A, 0x3B, 0x3E, 0x3F, 0x3C, 0, 1, 0x10 });
        e.unkC = ctx.int(u16);
        e.unkE = ctx.pick(u16, &.{ 0, 1 });
        e.unk10 = ctx.int(u32);
        e.unk14 = ctx.range(u8, 0, 116);
        e.unk15 = ctx.range(u8, 0, 101);
        e.unk16 = ctx.range(u8, 0, 97);
        e.unk17 = ctx.range(u8, 0, 90);
    }
    psx.put(&g_obj.unk40, &ents[0]);

    // Sixteen actors sharing one stats block; allegiance decides the 0x10 test.
    const stats = ctx.alloc(v.vs_battle_actor2);
    const actors = v.g.vs_battle_actors();
    for (0..16) |k| {
        const a = ctx.alloc(v.vs_battle_actor);
        psx.put(&a.stats, stats);
        a.allegiance = ctx.pick(u16, &.{ 0x10, 0x20, 0, 0xFFFF });
        actors[k] = a;
    }

    // Status string indices are read through this table: keep them in range.
    const ss = v.g.vs_battle_statusStrings();
    for (0..142) |k| ss[k] = ctx.range(u16, 0, 141);
    v.g.sceneMessages()[0] = ctx.range(u16, 0, 189);

    // Row entries are distinct within a row (row 0 even, row 1 odd), so a
    // value found in a row has exactly one index there.
    const c70 = v.g.D_800F4C70();
    for (0..2) |r| {
        for (0..16) |k| c70[r][k] = @intCast(k * 2 + r);
    }
    const cb0 = ctx.range(u8, 0, 16);
    const cb1 = ctx.range(u8, 1, 16);
    v.g.D_800F4CB0().* = cb0;
    v.g.D_800F4CB1().* = cb1;
    v.g.D_800F4CB2().* = ctx.range(u8, 0, 8);
    v.g.D_800F4CB3().* = ctx.range(u8, 0, 8);

    // unk2D: at the row-0 count (the clamp's equal case), at index 0, inside
    // row 0 or row 1, or any value.
    const k0: usize = if (cb0 < cb1) cb0 else 0;
    g_obj.unk2D = switch (ctx.range(u8, 0, 7)) {
        0, 1 => c70[0][k0],
        2 => c70[0][0],
        3 => c70[1][ctx.range(usize, 0, 15)],
        4 => c70[0][ctx.range(usize, 0, cb1 - 1)],
        5 => ctx.pick(u8, &.{ 0, 1, 23, 24, 255 }),
        else => ctx.int(u8),
    };

    const c98 = v.g.D_800F4C98();
    const c90 = v.g.D_800F4C90();
    const ca8 = v.g.D_800F4CA8();
    const ca0 = v.g.D_800F4CA0();
    for (0..8) |k| {
        c98[k] = ctx.edge(u8, &kinds);
        c90[k] = ctx.edge(u8, &kinds);
        ca8[k] = ctx.range(u8, 0, 40);
        ca0[k] = ctx.range(u8, 0, 40);
    }

    v.g.vs_main_buttonsPressed().all = ctx.int(u32);
    v.g.vs_main_buttonRepeat().* = ctx.int(i32);

    const mode = ctx.range(u8, 0, 99);
    const st: u8 = switch (mode) {
        0...3 => ctx.int(u8),
        4...13 => 0,
        14...53 => ctx.range(u8, 1, 15),
        54...61 => 16,
        62...65 => 17,
        66...72 => 18,
        73...82 => 19,
        83...85 => 20,
        86...88 => 21,
        else => ctx.range(u8, 22, 255),
    };
    v.g.D_800EABAA().* = st;

    const target: [*c]u8 = if (mode < 4) null else ctx.alloc(u8);
    return .{target};
}

pub fn classify(args: Args) usize {
    if (args[0] == null) return 0;
    return switch (v.g.D_800EABAA().*) {
        0 => 1,
        1...15 => 2,
        16 => 3,
        17 => 4,
        18 => 5,
        19 => 6,
        20 => 7,
        21 => 8,
        else => 9,
    };
}
