//! zig_diff spec: func_8007C580 -> func_8007C580.func_8007C580 (146C.c).
//! Inputs: the room door section pointer (null a quarter of the time, else a
//! fresh arena section), and two random ints (edge values picked often).
//! The C has no branches of its own. func_8007C4E0 may write the section
//! (unk8) and returns any int. func_800A1108 fills the four bytes of sp10
//! through its out-parameter, so the three fields passed on to func_8008B960
//! come from the callee, and the byte the C does not read (unk0_24) stays
//! unseen. func_8008B960 is a recording void stub.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007C580));

pub const classes = [_][:0]const u8{ "null-section", "section" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const sec: ?*v._mpdRoomDoorSection_t = if (ctx.chance(4)) null else ctx.alloc(v._mpdRoomDoorSection_t);
    const a1 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000 });
    const a2 = ctx.pick(c_int, &.{ 0, 1, -1, 0x7FFF_FFFF, -0x8000_0000 });
    return .{ sec, a1, a2 };
}

pub fn classify(args: Args) usize {
    return if (args[0] == null) 0 else 1;
}

pub const stubs = struct {
    pub fn func_8007C4E0(ctx: *zd.Ctx, a0: anytype, a1: anytype, a2: anytype) c_int {
        _ = a1;
        _ = a2;
        if (a0) |p| {
            const d: *v._mpdRoomDoorSection_t = @ptrCast(@alignCast(p));
            d.unk8 = ctx.value(u8);
        }
        return ctx.value(c_int);
    }

    pub fn func_800A1108(ctx: *zd.Ctx, a: anytype, out: anytype) c_int {
        _ = a;
        const bytes: [*]u8 = @ptrCast(@alignCast(out.?));
        for (0..4) |i| bytes[i] = ctx.value(u8);
        return ctx.value(c_int);
    }
};
