//! zig_diff spec: func_80074314 -> func_80074314.func_80074314 (146C.c).
//! Inputs: D_800F1910.unk0 points at an arena block whose two i16 fields
//! (the arguments of the last call) take edge values (0, +-1, the i16 extremes).
//! The stubs model what the C reads back: func_800CB50C and func_8008DEAC may
//! retarget D_800F1910.unk0 to a fresh block, and func_8008DEAC may rewrite the
//! two fields the C passes on. The C has no branches; _cameraMode and
//! vs_gametime_tickspeed are compared as state.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80074314));

pub const classes = [_][:0]const u8{ "first-negative", "first-nonnegative" };

pub const stubs = struct {
    pub fn func_800CB50C(ctx: *zd.Ctx) void {
        if (ctx.value(u2) == 0) psx.put(&v.g.D_800F1910().unk0, ctx.alloc(v._mpdRoomSectionA));
    }

    pub fn func_8008DEAC(ctx: *zd.Ctx, arg0: anytype, arg1: anytype) void {
        _ = arg1;
        const s: *v._mpdRoomSection9 = @ptrCast(@alignCast(arg0));
        if (ctx.value(u1) == 1) s.unk0 = ctx.value(i16);
        if (ctx.value(u1) == 1) s.unk2 = ctx.value(i16);
        if (ctx.value(u2) == 0) psx.put(&v.g.D_800F1910().unk0, ctx.alloc(v._mpdRoomSectionA));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v._mpdRoomSectionA);
    psx.put(&v.g.D_800F1910().unk0, obj);
    obj.unk0.unk0 = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });
    obj.unk0.unk2 = ctx.pick(i16, &.{ 0, -1, 1, 32767, -32768 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const obj: *v._mpdRoomSectionA = @ptrFromInt(psx.rawOf(v.g.D_800F1910().unk0));
    return if (obj.unk0.unk0 < 0) 0 else 1;
}
