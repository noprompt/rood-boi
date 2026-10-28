//! zig_diff spec: func_8007D41C -> func_8007D41C.func_8007D41C (146C.c).
//! Inputs: the global `D_800F1ABC` points at a fresh arena block of
//! `D_800F1ABC_t` (its bytes are random, so every poly, sprite and tail word
//! starts from random data). `D_800F1A78` is random bytes. The SetPolyFT4,
//! SetSemiTrans, SetSprt and GetTPage calls are recording stubs. The stubs
//! write what the real calls change (the poly/sprite tag and code, which the
//! loop copies), and GetTPage returns a random 16-bit value that the loop
//! stores into each tpage. The loop covers all ten entries, so every
//! iteration makes the `i < 10` comparison see its two sides equal at exit.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007D41C));

pub const classes = [_][:0]const u8{"object"};

pub const stubs = struct {
    pub fn SetPolyFT4(ctx: *zd.Ctx, p: anytype) void {
        const q: *v.POLY_FT4 = @ptrCast(@alignCast(p));
        q.tag = ctx.value(u32);
        q.code = ctx.value(u8);
    }

    pub fn SetSemiTrans(ctx: *zd.Ctx, p: anytype, abe: anytype) void {
        _ = abe;
        // `code` sits at byte 7 of both POLY_FT4 and SPRT.
        const bytes: [*]u8 = @ptrCast(p.?);
        bytes[7] = ctx.value(u8);
    }

    pub fn SetSprt(ctx: *zd.Ctx, p: anytype) void {
        const q: *v.SPRT = @ptrCast(@alignCast(p));
        q.tag = ctx.value(u32);
        q.code = ctx.value(u8);
    }

    pub fn GetTPage(ctx: *zd.Ctx, tp: anytype, abr: anytype, x: anytype, y: anytype) c_ushort {
        _ = tp;
        _ = abr;
        _ = x;
        _ = y;
        return ctx.value(c_ushort);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.D_800F1ABC_t);
    v.g.D_800F1ABC().* = obj;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return 0;
}
