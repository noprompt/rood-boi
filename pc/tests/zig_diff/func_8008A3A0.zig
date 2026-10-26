//! zig_diff spec: func_8008A3A0 -> func_8008A3A0.func_8008A3A0 (146C.c).
//! Inputs: the frame buffer index (0 or 1, re-read by the loop because
//! func_8007629C can change it), the two D_80055C80 frame buffers and the two
//! D_8005E0C0 heap blocks (arena blocks or null), the mpdEnemies guest pointer
//! (null, a PS1 low-RAM address with bit 31 set, or an arena block) and
//! D_800F192C (null, a low-RAM address, or an arena block). The callees that
//! can change state the C reads back (func_8008ABF0 clears mpdEnemies,
//! func_8007629C moves the frame buffer, func_800E7454 clears D_800F192C)
//! do so in some calls. Every other call is a recording stub.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008A3A0));

pub const classes = [_][:0]const u8{
    "enemies-null-ref-null",
    "enemies-set-ref-null",
    "enemies-null-ref-set",
    "enemies-set-ref-set",
};

/// A pointer into PS1 address 0 as the host maps it (low RAM at 0x80000000),
/// sign bit set, 16-byte aligned. Never dereferenced by the stubs.
fn lowAddr(ctx: *zd.Ctx) usize {
    return 0x8000_0000 + (@as(usize, ctx.int(u16)) & 0x7FF0);
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const zc = v.g._zoneContext();

    // Frame buffers and heap blocks: arena pointers below 4 GB (psx_addr).
    const frames = v.g.D_80055C80();
    frames[0] = ctx.alloc(u64);
    frames[1] = ctx.alloc(u64);
    v.g.vs_main_frameBuf().* = ctx.range(i32, 0, 1);

    const frees = v.g.D_8005E0C0();
    frees[0] = if (ctx.chance(3)) null else ctx.alloc(u64);
    frees[1] = if (ctx.chance(3)) null else ctx.alloc(u64);

    // mpdEnemies: null, a low-RAM guest address (sign bit set), or an arena block.
    const roll = ctx.range(u8, 0, 2);
    const mpd: ?*anyopaque = switch (roll) {
        0 => null,
        1 => @ptrFromInt(lowAddr(ctx)),
        else => ctx.alloc(v._mpdEnemy),
    };
    psx.put(&zc.mpdEnemies, mpd);

    // D_800F192C: null, a low-RAM native pointer, or an arena block.
    const ref = ctx.range(u8, 0, 2);
    v.g.D_800F192C().* = switch (ref) {
        0 => null,
        1 => @ptrFromInt(lowAddr(ctx)),
        else => ctx.alloc(v.vs_battle_actor),
    };

    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const zc = v.g._zoneContext();
    const e: usize = if (psx.get(zc.mpdEnemies) != null) 2 else 0;
    const r: usize = if (v.g.D_800F192C().* != null) 1 else 0;
    return e + r;
}

pub const stubs = struct {
    pub fn func_8007629C(ctx: *zd.Ctx, otag: anytype) c_int {
        _ = otag;
        // The transition can flip the display buffer: the loop must re-read it.
        if (ctx.value(u2) == 0) v.g.vs_main_frameBuf().* = @as(i32, ctx.value(u1));
        return ctx.value(c_int);
    }

    pub fn func_8008ABF0(ctx: *zd.Ctx, arg0: anytype) c_int {
        _ = arg0;
        // The room setup can drop the enemy buffer: the C reads it after this call.
        if (ctx.value(u2) == 0) psx.put(&v.g._zoneContext().mpdEnemies, @as(?*anyopaque, null));
        return ctx.value(c_int);
    }

    pub fn func_800E7454(ctx: *zd.Ctx, p: anytype) void {
        _ = p;
        if (ctx.value(u2) == 0) v.g.D_800F192C().* = null;
    }
};
