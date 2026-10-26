//! zig_diff spec: func_8006C5AC -> func_8006C5AC.func_8006C5AC (146C.c).
//! Inputs: arg0 an index 0-15 into vs_battle_actors, the actor there in the
//! arena with equippedWeaponCategory 0-11 or 255 (every inner switch case and
//! both default paths). The D_800F19CC block holds all four sub-blocks
//! (unk854[0..3]) with valid entry counts 0-30, so whichever sub-block the
//! C selects with unk0 & 3 (any value of unk0), and any sub-block a porter
//! might select instead, is safe to read. The selected sub-block takes the
//! input class: none, all skipped (unk40 != 0), 0/1/2/4, 3, 5, or another
//! value. Entries mostly have unk40 == 0. The stub func_800A1108 writes the
//! SVECTOR the C reads back; the stub for vs_main_panSfx copies the vector it
//! is given into the arena so the call trace sees its contents.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006C5AC));

pub const classes = [_][:0]const u8{ "no-entries", "all-skipped", "group-0-1-2-4", "group-3", "group-5", "other-kind" };

var last_class: usize = 0;

pub const stubs = struct {
    pub fn func_800A1108(ctx: *zd.Ctx, target: anytype, out: anytype) c_int {
        _ = target;
        const raw: ?*anyopaque = out;
        // sp10.unk0.unk4 (an SVECTOR at byte 4) is what the C reads back.
        psx.byteAt(i16, raw.?, 4).* = ctx.value(i16);
        psx.byteAt(i16, raw.?, 6).* = ctx.value(i16);
        psx.byteAt(i16, raw.?, 8).* = ctx.value(i16);
        return ctx.value(c_int);
    }

    pub fn vs_main_panSfx(ctx: *zd.Ctx, a: anytype, b: anytype, vec: anytype) void {
        _ = a;
        _ = b;
        const out = ctx.alloc([3]i16);
        const src: *align(1) const [3]i16 = @ptrCast(vec);
        out.* = src.*;
    }
};

fn fillBlock(ctx: *zd.Ctx, t: *v.D_800F19CC_t2, class: usize) void {
    const count: u16 = if (class == 0) 0 else ctx.range(u16, 1, 30);
    t.unk4A = count;

    const kind: u8 = switch (class) {
        2 => ctx.edge(u8, &.{ 0, 1, 2, 4 }),
        3 => 3,
        4 => 5,
        5 => ctx.edge(u8, &.{ 6, 7, 8, 255 }),
        else => ctx.int(u8),
    };

    for (0..@as(usize, count)) |i| {
        const e = &t.unk4C[i];
        e.unk0.targetActor = ctx.int(u8);
        e.unk0.unk3 = kind;
        e.unk40 = if (class == 1 or ctx.chance(5))
            ctx.edge(i32, &.{ 1, -1, 0x4000_0000 })
        else
            0;
    }
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const blk = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = blk;
    blk.unk0 = ctx.int(u32);
    const sel: usize = @intCast(blk.unk0 & 3);

    const class = ctx.range(usize, 0, 5);
    last_class = class;
    for (0..4) |b| {
        fillBlock(ctx, &blk.unk854[b], if (b == sel) class else ctx.range(usize, 0, 5));
    }

    const actor = ctx.alloc(v.vs_battle_actor);
    actor.equippedWeaponCategory = ctx.edge(u8, &.{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 255 });
    const arg0 = ctx.range(c_int, 0, 15);
    v.g.vs_battle_actors()[@intCast(arg0)] = actor;
    return .{arg0};
}

pub fn classify(args: Args) usize {
    _ = args;
    return last_class;
}
