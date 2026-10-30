//! zig_diff spec: func_8008BD74 -> func_8008BD74.func_8008BD74 (146C.c).
//! Inputs: a room section in the arena with random i16 coordinates (edges:
//! 0, +-1, 32767, -32768, 3..8) and a type selector unk6 drawn from
//! {3, 4, 5, 6, 7, 8, -1, 32767, -32768}, so the `unk6 >= 4` test sees its
//! sides equal, the switch takes cases 0-3 and the default, and the
//! `&&` short-circuits both ways. The lookup stub returns null about 40%
//! of the time, otherwise one of two arena objects (the same one for both
//! calls sometimes), and sometimes rewrites that object's unk0_10 bits
//! before returning, so the XOR reads back a changed value.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008BD74));

pub const classes = [_][:0]const u8{ "unk6-below-4", "unk6-equal-4", "unk6-case-1-3", "unk6-default" };

var objs: [2]*v._mpdRoomSection3 = undefined;

pub const stubs = struct {
    pub fn func_8008B764(ctx: *zd.Ctx, arg0: anytype, arg1: anytype, arg2: anytype) ?*v._mpdRoomSection3 {
        _ = arg0;
        _ = arg1;
        _ = arg2;
        if (ctx.value(u8) < 100) return null;
        const obj = objs[ctx.value(u1)];
        if (ctx.value(u1) == 1) psx.setBits(obj, "unk0_10", ctx.value(u3));
        return obj;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    objs[0] = ctx.alloc(v._mpdRoomSection3);
    objs[1] = ctx.alloc(v._mpdRoomSection3);
    const sec = ctx.alloc(v._mpdRoomSectionA);
    const coord = [_]i16{ 0, 1, -1, 32767, -32768, 3, 4, 5, 6, 7, 8 };
    sec.unk0.unk0 = ctx.pick(i16, &coord);
    sec.unk0.unk2 = ctx.pick(i16, &coord);
    sec.unk0.unk4 = ctx.pick(i16, &coord);
    sec.unk0.unk6 = ctx.edge(i16, &.{ 3, 4, 4, 5, 6, 7, 8, -1, 32767, -32768 });
    return .{sec};
}

pub fn classify(args: Args) usize {
    const k = args[0].?.unk0.unk6;
    if (k < 4) return 0;
    if (k == 4) return 1;
    if (k <= 7) return 2;
    return 3;
}
