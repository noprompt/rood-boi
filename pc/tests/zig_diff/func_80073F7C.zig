//! zig_diff spec: func_80073F7C -> func_80073F7C.func_80073F7C (146C.c).
//! Inputs: a scene section (null only when no message is shown), a random
//! camera block, an int from edge values, and the information setting (0, 1,
//! 0x80, 0xFF, 2 or random). The message reads the section's unk6, so the
//! section is non-null whenever the setting is nonzero. The two callees write
//! the globals the C reads back (D_800F196C, the setting, the camera's unkC),
//! so a port that stores late or reads early is caught by the call traces.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80073F7C));

pub const classes = [_][:0]const u8{ "no-message-null-section", "no-message", "message" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const info = ctx.pick(u8, &.{ 0, 1, 0x80, 0xFF, 2 });
    v.g.vs_main_settings().information = info;
    // The C stores through this pointer unconditionally.
    v.g.D_800F19CC().* = ctx.alloc(v.D_800F19CC_t);
    const camera = ctx.alloc(v.func_8006EBF8_t3);
    // Null is only safe when no message reads the section.
    const section: ?*v._mpdRoomSectionA = if (info == 0 and ctx.chance(3))
        null
    else
        ctx.alloc(v._mpdRoomSectionA);
    if (section) |s| s.unk0.unk6 = ctx.pick(i16, &.{ 32767, -32768, -6, 0, -1 });
    const arg2 = ctx.pick(c_int, &.{ 0, -1, 1, 0x7fff_ffff, -0x8000_0000 });
    return .{ section, camera, arg2 };
}

pub fn classify(args: Args) usize {
    if (args[0] == null) return 0;
    return if (v.g.vs_main_settings().information == 0) 1 else 2;
}

pub const stubs = struct {
    // Writes the globals the C stores before and after this call.
    pub fn func_8006EF10(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g.D_800F196C().* = ctx.value(u32);
        if (ctx.value(u2) == 0) v.g.vs_main_settings().information = 0;
    }

    // Writes the camera block the C stored, and may clear the setting. It only
    // ever writes zero to the setting, so a null section stays safe.
    pub fn func_8009E5C4(ctx: *zd.Ctx, i: anytype) void {
        _ = i;
        if (ctx.value(u2) == 0) v.g.vs_main_settings().information = 0;
        if (ctx.value(u2) == 0) v.g.D_800F1910().unk4.unkC = ctx.value(i32);
    }
};
