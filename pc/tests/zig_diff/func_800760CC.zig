//! zig_diff spec: func_800760CC -> func_800760CC.func_800760CC (146C.c).
//! Inputs: the six arguments as the C reads them. arg1 is below, at and above
//! 16, so temp_s3 = arg1 - 16 has or lacks its sign bit (the case the
//! `>> 0x1F` correction covers). arg0 is zero, odd, negative and at the
//! extremes (the `/ 2`, and the i16 store of D_8005DFD6). arg3..arg5 include
//! values wider than a byte (truncated by the u8 stores). The frame buffer
//! index is 0, 1, 2 or -1: the C only takes addresses from it. The environment
//! setters are recording stubs that write fields the C reads back nowhere.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
const c = @import("c_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800760CC));

pub const classes = [_][:0]const u8{ "temp-sign-bit", "temp-zero", "temp-positive" };

pub const stubs = struct {
    pub fn SetGeomOffset(ctx: *zd.Ctx, ofx: anytype, ofy: anytype) void {
        _ = ctx;
        _ = ofx;
        _ = ofy;
    }

    pub fn SetGeomScreen(ctx: *zd.Ctx, h: anytype) void {
        _ = ctx;
        _ = h;
    }

    pub fn SetDefDispEnv(ctx: *zd.Ctx, env: anytype, x: anytype, y: anytype, w: anytype, h: anytype) [*c]c.DISPENV {
        const d: *v.DISPENV = @ptrCast(@alignCast(env));
        d.disp = .{ .x = @truncate(x), .y = @truncate(y), .w = @truncate(w), .h = @truncate(h) };
        d.screen.x = ctx.value(i16);
        d.isinter = ctx.value(u8);
        return env;
    }

    pub fn SetDefDrawEnv(ctx: *zd.Ctx, env: anytype, x: anytype, y: anytype, w: anytype, h: anytype) [*c]c.DRAWENV {
        const d: *v.DRAWENV = @ptrCast(@alignCast(env));
        d.clip = .{ .x = @truncate(x), .y = @truncate(y), .w = @truncate(w), .h = @truncate(h) };
        d.tpage = ctx.value(u16);
        return env;
    }

    pub fn PutDispEnv(ctx: *zd.Ctx, env: anytype) [*c]c.DISPENV {
        return if (ctx.value(u1) == 1) null else env;
    }

    pub fn PutDrawEnv(ctx: *zd.Ctx, env: anytype) [*c]c.DRAWENV {
        return if (ctx.value(u1) == 1) null else env;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.vs_main_frameBuf().* = ctx.edge(i32, &.{ 0, 1, 0, 1, 2, -1 });

    const arg0 = ctx.pick(c_int, &.{ 0, 1, -1, 2, -2, 255, 256, 511, 512, 0x7FFF, -0x8000, 0x7FFF_FFFF, -0x8000_0000 });
    const arg1: c_int = switch (ctx.range(u8, 0, 3)) {
        0 => ctx.range(c_int, 0, 15),
        1 => 16,
        2 => ctx.range(c_int, 17, 240),
        else => ctx.int(c_int),
    };
    const arg2 = ctx.pick(c_int, &.{ 0, 1, -1, 256, 0x7FFF_FFFF });
    const arg3 = ctx.pick(c_int, &.{ 0, 255, 256, -1, 0x1FF });
    const arg4 = ctx.pick(c_int, &.{ 0, 255, 256, -1, 0x1FF });
    const arg5 = ctx.pick(c_int, &.{ 0, 255, 256, -1, 0x1FF });

    return .{ arg0, arg1, arg2, arg3, arg4, arg5 };
}

pub fn classify(args: Args) usize {
    const t: u32 = @bitCast(args[1] -% 16);
    if ((t & 0x8000_0000) != 0) return 0;
    return if (t == 0) 1 else 2;
}
