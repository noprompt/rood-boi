//! zig_diff spec: func_80089888 -> func_80089888.func_80089888 (146C.c).
//! The unit takes no arguments, so the inputs are the globals it reads. D_800F1AB0 gets its
//! flag bit unk4_15 clear or set and its selector unk4_13 at each of 0-3; its other bitfields,
//! the scratchpad and the arena stay random. The stubs of func_8009D458 and func_800A30A0 write
//! the bitfields the C reads back (unk2.unk0_13, unk4_8, unk4_13, unk4_15, unk6_10), so the
//! port must read them after the calls. func_800A30A0 and func_800A9D24 echo their argument
//! structs into the scratch view, so a wrong byte of sp28 or sp10 reaches the state. The
//! switch's default arm cannot be reached: unk4_13 is a 2-bit selector covering all four cases.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80089888));

pub const classes = [_][:0]const u8{ "flag-clear", "flag-set-sel0", "flag-set-sel1", "flag-set-sel2", "flag-set-sel3" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = v.g.D_800F1AB0();
    // The flag is set about half the time.
    psx.setBits(d, "unk4_15", @intFromBool(!ctx.chance(2)));
    psx.setBits(d, "unk4_13", ctx.edge(u2, &.{ 0, 1, 2, 3 }));
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F1AB0();
    if (psx.getBits(d, "unk4_15") == 0) return 0;
    return 1 + @as(usize, psx.getBits(d, "unk4_13"));
}

pub const stubs = struct {
    pub fn func_8009D458(ctx: *zd.Ctx) void {
        const d = v.g.D_800F1AB0();
        if (ctx.value(u1) == 1) psx.setBits(&d.unk2, "unk0_13", ctx.value(u3));
        if (ctx.value(u1) == 1) psx.setBits(d, "unk4_8", ctx.value(u5));
        if (ctx.value(u1) == 1) psx.setBits(d, "unk4_13", ctx.value(u2));
        if (ctx.value(u1) == 1) psx.setBits(d, "unk4_15", ctx.value(u1));
        if (ctx.value(u1) == 1) psx.setBits(d, "unk6_10", ctx.value(u5));
    }

    pub fn func_800A30A0(ctx: *zd.Ctx, id: anytype, p: anytype, x: anytype, y: anytype) void {
        _ = id;
        _ = x;
        _ = y;
        const s: *v.func_80089888_t = @ptrCast(@alignCast(if (@typeInfo(@TypeOf(p)) == .optional) p.? else p));
        const f: u32 = (@as(u32, s.unk0_0) << 24) | (@as(u32, s.unk0_8) << 16) |
            (@as(u32, s.unk0_16) << 8) | @as(u32, psx.getBits(s, "unk0_24"));
        v.g.vs_scratch().firstPersonViewFacing = f;
        const d = v.g.D_800F1AB0();
        // The callee may change the selector and the flag the C reads next.
        if (ctx.value(u1) == 1) psx.setBits(d, "unk4_15", ctx.value(u1));
        if (ctx.value(u1) == 1) psx.setBits(d, "unk4_13", ctx.value(u2));
    }

    pub fn func_800A9D24(ctx: *zd.Ctx, id: anytype, p: anytype, k: anytype) void {
        _ = ctx;
        _ = id;
        _ = k;
        const r: *v.SVECTOR = @ptrCast(@alignCast(p));
        const m = &v.g.vs_scratch().viewMatrix;
        m.t[0] = r.vx;
        m.t[1] = r.vy;
        m.t[2] = r.vz;
    }

    pub fn func_800A1108(ctx: *zd.Ctx, id: anytype, p: anytype) c_int {
        _ = id;
        _ = p;
        return ctx.value(c_int);
    }
};
