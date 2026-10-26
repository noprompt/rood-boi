//! zig_diff spec: func_8006F4B0 -> func_8006F4B0.func_8006F4B0 (146C.c).
//! Inputs: a valid arg0 object in the arena with random bitfield bytes (unk0_0 and
//! unk0_16 take edge values 0, 1, 0x7F, 0x80, 0xFF) and an i16 vx/vy, and the global
//! D_800F1868 set to edge flags so that bit 1 is set or clear and the sign bit is
//! set or clear (four classes). The callee func_800CF3F8 is a recording stub: it
//! copies the fields of the sp10 it is given into an arena object (the C's stack is
//! not compared, so the copy is what makes sp10 observable), may rewrite the global,
//! and returns any c_int. Only the fields the C sets are copied, so uninitialised
//! stack bytes never reach the comparison.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006F4B0));

pub const classes = [_][:0]const u8{ "bit1-set-pos", "bit1-set-neg", "bit1-clear-pos", "bit1-clear-neg" };

/// The arena object the stub copies the callee's argument block into (set by prepare).
var sink: ?*v.func_800CF0E8_t = null;

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg = ctx.alloc(v.func_8006EBF8_t3);
    sink = ctx.alloc(v.func_800CF0E8_t);
    arg.unk0._bytes[0] = ctx.pick(u8, &.{ 0, 1, 0x7F, 0x80, 0xFF });
    arg.unk0._bytes[2] = ctx.pick(u8, &.{ 0, 1, 0x7F, 0x80, 0xFF });
    arg.unk4.vx = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
    arg.unk4.vy = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
    const flag = ctx.pick(i32, &.{ 0, 1, 2, 3, 4, -2, -1, 0x7FFF_FFFE, std.math.minInt(i32), 0x7FFF_FFFF });
    v.g.D_800F1868().* = flag;
    return .{arg};
}

pub fn classify(args: Args) usize {
    _ = args;
    const flag = v.g.D_800F1868().*;
    const set = (flag & 2) != 0;
    const neg = flag < 0;
    return (if (set) @as(usize, 0) else 2) + (if (neg) @as(usize, 1) else 0);
}

pub const stubs = struct {
    pub fn func_800CF3F8(ctx: *zd.Ctx, p: anytype, n: anytype) c_int {
        _ = n;
        const s: *v.func_800CF0E8_t = @ptrCast(@alignCast(p));
        const out = sink.?;
        // Only the fields the C writes, so the comparison never sees stack garbage.
        out.effectId = s.effectId;
        out.unk2 = s.unk2;
        out.unk3 = s.unk3;
        out.unk4 = s.unk4;
        out.unk8.u8[0] = s.unk8.u8[0];
        out.unk10 = s.unk10;
        out.unk14.u16 = s.unk14.u16;
        out.unk16.u16 = s.unk16.u16;
        out.unk18 = s.unk18;
        if (ctx.value(u1) == 1) s.unk1A = ctx.value(i16);
        if (ctx.value(u1) == 1) v.g.D_800F1868().* = ctx.value(i32);
        return ctx.value(c_int);
    }
};
