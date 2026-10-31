//! zig_diff spec: func_800D0C60 -> func_800D0C60.func_800D0C60 (5BF94.c).
//! Inputs: a func_800D0C60_t in the arena with unk34 chosen from the edges
//! around 0x10 (below, 0x10, 0x11, 0x12, 0x13, 0x00, 0xFF) or any byte, unk35
//! any byte, and arg0 at the integer edges. The callees are recording stubs
//! that write what the real ones can change: the pad and vz fields of the
//! sp10 block (the C reads pad back), sp20, the unk78 block, and arg1's
//! fields through func_800D0984 and func_800D0B08.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D0C60));

pub const classes = [_][:0]const u8{ "below-0x10", "x10", "x11", "x12", "default" };

pub const stubs = struct {
    pub fn func_800A1108(ctx: *zd.Ctx, id: anytype, out: anytype) c_int {
        _ = id;
        const bytes: [*]u8 = @ptrCast(@alignCast(out.?));
        std.mem.writeInt(i16, bytes[8..][0..2], ctx.value(i16), .little); // unk0.unk4.vz
        std.mem.writeInt(i16, bytes[10..][0..2], ctx.value(i16), .little); // unk0.unk4.pad
        return ctx.value(c_int);
    }

    pub fn func_800A1720(ctx: *zd.Ctx, a: anytype, b: anytype, unk78: anytype, out: anytype) void {
        _ = a;
        _ = b;
        const o: *[2]i32 = @ptrCast(@alignCast(out.?));
        o[0] = ctx.value(i32);
        o[1] = ctx.value(i32);
        if (ctx.value(u1) == 1) {
            const t: *v.func_800CFE98_t = @ptrCast(@alignCast(unk78));
            t.unk0 = ctx.value(i32);
            t.unkC = ctx.value(i32);
        }
    }

    pub fn func_800D0984(ctx: *zd.Ctx, arg0: anytype, t: anytype, flag: anytype) void {
        _ = arg0;
        _ = flag;
        const s: *v.func_800D0C60_t = @ptrCast(@alignCast(t));
        s.unk35 = ctx.value(u8);
        s.unkBE = ctx.value(i16);
        if (ctx.value(u1) == 1) s.unk34 = ctx.value(u8);
    }

    pub fn func_800D0B08(ctx: *zd.Ctx, t: anytype) void {
        const s: *v.func_800CFE98_t = @ptrCast(@alignCast(t));
        s.unk4 = ctx.value(i32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.func_800D0C60_t);
    obj.unk34 = ctx.pick(u8, &.{ 0x0F, 0x10, 0x11, 0x12, 0x13, 0x00, 0xFF });
    obj.unk35 = ctx.int(u8);
    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000 });
    return .{ arg0, obj };
}

pub fn classify(args: Args) usize {
    const u = args[1].?.unk34;
    if (u < 0x10) return 0;
    return switch (u) {
        0x10 => 1,
        0x11 => 2,
        0x12 => 3,
        else => 4,
    };
}
