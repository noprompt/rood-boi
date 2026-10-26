//! zig_diff spec: func_8006C84C -> func_8006C84C.func_8006C84C (146C.c).
//! Inputs: a D_800F19CC_t in the arena whose selected unk854 entry has 0-32
//! entries (30 and up run past unk4C into the bytes after it, as the C does),
//! entries with unk40 of 0, 1, -1, INT_MIN or random and unk3 of 0-7 or 255,
//! an actionIndex around 0x16 and 0x28 (or any u16), and per-action
//! prerequisiteFunction values of 3 or random. The two callees are recording
//! stubs that write back what the C reads again: func_8006C4C4 can change the
//! next entry's unk40, and func_8006C5AC can change the selected entry's
//! unk4A and actionIndex (the loop bound and the routing are re-read).
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006C84C));

pub const classes = [_][:0]const u8{ "no-entries", "first-entry-live", "action-high", "prereq-3", "switch" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const t = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = t;
    const sel = &t.unk854[t.unk0 & 3];

    sel.actionIndex = ctx.pick(u16, &.{ 0, 0x15, 0x16, 0x17, 0x27, 0x28, 0x29, 0xFFFF });
    sel.unk4A = ctx.edge(u16, &.{ 0, 1, 2, 29, 30, 31, 32 });

    for (&sel.unk4C) |*e| {
        e.unk40 = ctx.pick(i32, &.{ 0, 0, 1, -1, std.math.minInt(i32) });
        e.unk0.unk3 = ctx.edge(u8, &.{ 0, 1, 2, 3, 4, 5, 6, 7, 255 });
    }

    const actions = v.g.actions();
    for (0..40) |k| {
        psx.setBits(&actions[k].hitParams[0], "prerequisiteFunction", if (ctx.chance(2)) @as(u6, 3) else ctx.int(u6));
    }

    return .{ctx.pick(c_int, &.{ 0, 1, -1 })};
}

pub fn classify(args: Args) usize {
    _ = args;
    const t = v.g.D_800F19CC().*.?;
    const sel = &t.unk854[t.unk0 & 3];
    if (sel.unk4A == 0) return 0;
    if (sel.actionIndex >= 0x28) return 2;
    if (psx.getBits(&v.g.actions()[sel.actionIndex].hitParams[0], "prerequisiteFunction") == 3) return 3;
    if (sel.unk4C[0].unk40 != 0) return 1;
    return 4;
}

pub const stubs = struct {
    pub fn func_8006C4C4(ctx: *zd.Ctx, action: anytype, entity: anytype, flag: anytype) void {
        _ = action;
        _ = flag;
        if (ctx.value(u2) == 0) {
            const e: *v._hitEntity_t = @ptrCast(@alignCast(entity));
            const next: *v._hitEntity_t = @ptrFromInt(@intFromPtr(e) + @sizeOf(v._hitEntity_t));
            next.unk40 = ctx.value(i32);
        }
    }

    pub fn func_8006C5AC(ctx: *zd.Ctx, arg: anytype) c_int {
        _ = arg;
        const t = v.g.D_800F19CC().*.?;
        const sel = &t.unk854[t.unk0 & 3];
        if (ctx.value(u2) == 0) sel.unk4A = ctx.value(u16) & 31;
        if (ctx.value(u3) == 0) sel.actionIndex = ctx.value(u16);
        return ctx.value(c_int);
    }
};
