//! zig_diff spec: func_8007BE20 -> func_8007BE20.func_8007BE20 (146C.c).
//! Inputs: the 16 vs_battle_actors slots each null or an arena actor, in four
//! shapes (all null; all present with arg1 outside 0..15; all present with arg1
//! inside, so 15 entries are recorded; random presence), and arg1 from edges
//! (in range, 15, 16, -1, 255). arg0 is any value (it becomes effectId). The
//! callee's request is copied into an arena block, field by field, so the
//! fields the C writes into sp10 (not only the call's arguments) are compared.
//! Uninitialised stack fields are not copied.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007BE20));

pub const classes = [_][:0]const u8{ "none-recorded", "some-recorded", "fifteen-recorded", "all-sixteen-recorded" };

/// The request fields the callee sees, copied into the arena each call.
const Capture = struct {
    effectId: u16,
    unk2: u8,
    unk3: u8,
    unk4: u16,
    unk8: i16,
    unkA: i16,
    unkC: i16,
    unk10: i16,
    unk14: u8,
    unk16: u8,
    unkD0: [16]u8,
};

var cap: ?*Capture = null;

pub const stubs = struct {
    pub fn func_800CF0E8(ctx: *zd.Ctx, req: anytype, a: anytype, b: anytype) c_int {
        _ = a;
        _ = b;
        const r: *const v.func_800CF0E8_t = @ptrCast(@alignCast(req));
        const out = cap orelse unreachable;
        out.effectId = r.effectId;
        out.unk2 = r.unk2;
        out.unk3 = r.unk3;
        out.unk4 = r.unk4;
        out.unk8 = r.unk8.s16;
        out.unkA = r.unkA.s16;
        out.unkC = r.unkC;
        out.unk10 = r.unk10;
        out.unk14 = r.unk14.u8[0];
        out.unk16 = r.unk16.u8[0];
        const n: usize = @min(@as(usize, r.unk3), 16);
        for (0..n) |k| out.unkD0[k] = r.unkD0[k];
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    cap = ctx.alloc(Capture);
    const tbl = v.g.vs_battle_actors();
    const mode = ctx.range(u8, 0, 9);
    var arg1: c_int = ctx.pick(c_int, &.{ 0, 1, 7, 15, 16, -1, 255 });

    var i: usize = 0;
    while (i < 16) : (i += 1) {
        const present = switch (mode) {
            0, 1 => false,
            2, 3, 4, 5 => true,
            else => ctx.chance(2) == false,
        };
        tbl[i] = if (present) ctx.alloc(v.vs_battle_actor) else null;
    }

    if (mode == 2 or mode == 3) arg1 = ctx.edge(c_int, &.{ 16, -1, 255 });
    if (mode == 4 or mode == 5) arg1 = ctx.range(c_int, 0, 15);

    return .{ ctx.pick(c_int, &.{ 0, 1, -1, 0xFFFF, 0x10000 }), arg1 };
}

pub fn classify(args: Args) usize {
    const tbl = v.g.vs_battle_actors();
    var n: usize = 0;
    var i: usize = 0;
    while (i < 16) : (i += 1) {
        if (tbl[i] != null and @as(c_int, @intCast(i)) != args[1]) n += 1;
    }
    if (n == 0) return 0;
    if (n == 15) return 2;
    if (n == 16) return 3;
    return 1;
}
