//! zig_diff spec: func_8008EC48 -> func_8008EC48.func_8008EC48 (146C.c).
//! Inputs take one of nine paths per run. The tile path draws a layout whose
//! width and height are inside 1..31 (or just outside: 0, -1, 32, 33, INT_MAX).
//! A layout slot left null with the tile flag set falls through to the other
//! paths. The primitive path has a tint (nonzero unk6 with random i8 channels)
//! or none. The camera path takes an angles argument or null, with farClip
//! 4096 or another value and room sectionB null or set. Camera positions are
//! random i32 values in a range where the C's multiplications cannot overflow.
//! The camera stubs copy the position they are given into the scratchpad
//! (viewMatrix.t), so a wrong position value reaches the compared state. The
//! pc_hw_anchor_packets branch is a weak hook the harness never links, so its
//! taken side is waived.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");

pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008EC48));

pub const classes = [_][:0]const u8{
    "tiles-in-range",
    "tiles-out-of-range",
    "prim-tinted",
    "prim-plain",
    "camera-arg-far-4096",
    "camera-arg-far-other",
    "camera-null-room",
    "camera-null-default",
};

fn inRange(x: i32) bool {
    return @as(u32, @bitCast(x -% 1)) < 31;
}

fn scratch() *v.vs_scratch_t {
    return @ptrFromInt(zd.scratchpad);
}

fn setupCamera(ctx: *zd.Ctx) void {
    const sc = scratch();
    const room = v.g.vs_battle_roomData();
    sc.camera.position.vx = ctx.range(i32, -(1 << 30), (1 << 30) - 1);
    sc.camera.position.vy = ctx.range(i32, -(1 << 30), (1 << 30) - 1);
    sc.camera.position.vz = ctx.range(i32, -(1 << 30), (1 << 30) - 1);
    sc.camera.angles.vx = ctx.range(i32, -65535, 65535);
    sc.camera.angles.vy = ctx.range(i32, -65535, 65535);
    sc.camera.farClip = ctx.edge(i32, &.{ 4096, 4096, 0, 1, -1, 4095, 4097, -4096, 2048, -300, 300 });
    psx.put(&room.sectionB, if (ctx.chance(2)) null else ctx.alloc(v._mpdRoomSectionB));
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const sc = scratch();
    const dc9 = v.g.D_800F1DC9();
    const dc6 = v.g.D_800F1DC6();
    const layoutSlot = v.g.D_800F1DCC();
    const tint = v.g.D_800F1BB0();

    dc9.* = 0;
    dc6.* = 0;
    layoutSlot.* = null;
    var arg: ?*v.VECTOR = null;

    const which = ctx.range(u8, 0, 8);
    switch (which) {
        0, 1 => {
            dc9.* = ctx.edge(u8, &.{ 1, 0x80, 0xFF });
            const layout = ctx.alloc(v.vs_battle_backgroundLayout);
            layout.width = ctx.edge(i32, &.{ 1, 2, 15, 30, 31 });
            layout.height = ctx.edge(i32, &.{ 1, 2, 15, 30, 31 });
            layoutSlot.* = layout;
        },
        2 => {
            dc9.* = ctx.edge(u8, &.{ 1, 0x80, 0xFF });
            const layout = ctx.alloc(v.vs_battle_backgroundLayout);
            layout.width = ctx.edge(i32, &.{ 0, -1, 32, 33, 100, 0x7FFF_FFFF });
            layout.height = ctx.edge(i32, &.{ 1, 2, 31, 32 });
            layoutSlot.* = layout;
        },
        3 => {
            dc9.* = ctx.edge(u8, &.{ 1, 0x80, 0xFF });
            const layout = ctx.alloc(v.vs_battle_backgroundLayout);
            layout.width = ctx.edge(i32, &.{ 1, 2, 31 });
            layout.height = ctx.edge(i32, &.{ 0, -1, 32, 33, 0x7FFF_FFFF });
            layoutSlot.* = layout;
        },
        4, 5 => {
            dc6.* = ctx.edge(u8, &.{ 1, 0x80, 0xFF });
            const prim = ctx.alloc(v.POLY_FT4);
            psx.put(&sc.unk0, prim);
            const ot: *anyopaque = @ptrCast(ctx.allocBytes(0x2000, 16));
            psx.put(&sc.unk4, ot);
            if (which == 4) {
                tint.unk0 = ctx.int(i8);
                tint.unk1 = ctx.int(i8);
                tint.unk2 = ctx.int(i8);
                tint.unk6 = ctx.edge(i16, &.{ 1, -1, 0x100 });
            } else {
                tint.unk6 = 0;
            }
        },
        6, 7, 8 => {
            // 8: the tile flag is set but no layout is, so the C tests the
            // primitive flag (clear here) and then the camera path.
            if (which == 8) dc9.* = ctx.edge(u8, &.{ 1, 0x80, 0xFF });
            setupCamera(ctx);
            if (which == 6 or (which == 8 and ctx.chance(2))) arg = ctx.alloc(v.VECTOR);
        },
        else => unreachable,
    }
    return .{arg};
}

pub fn classify(args: Args) usize {
    const sc = scratch();
    const dc9 = v.g.D_800F1DC9().*;
    const layout = v.g.D_800F1DCC().*;
    if (dc9 != 0 and layout != null) {
        const l = layout.?;
        return if (inRange(l.width) and inRange(l.height)) 0 else 1;
    }
    if (v.g.D_800F1DC6().* != 0) {
        return if (v.g.D_800F1BB0().unk6 != 0) 2 else 3;
    }
    if (args[0]) |_| {
        return if (sc.camera.farClip == 4096) 4 else 5;
    }
    return if (psx.get(v.g.vs_battle_roomData().sectionB) != null) 6 else 7;
}

fn fillMatrix(ctx: *zd.Ctx, out: anytype) void {
    const m: *v.MATRIX = @ptrCast(@alignCast(out));
    for (&m.m) |*row| {
        for (row) |*e| e.* = ctx.value(i16);
    }
    for (&m.t) |*e| e.* = ctx.value(i32);
}

// The position the C builds is the only input these callees get, so the
// stubs copy it into the scratchpad (state the harness compares).
fn recordPosition(pos: anytype) void {
    const p: *const v.VECTOR = @ptrCast(@alignCast(pos));
    scratch().viewMatrix.t = .{ p.vx, p.vy, p.vz };
}

pub const stubs = struct {
    pub fn func_80098648(ctx: *zd.Ctx, pos: anytype, angles: anytype, out: anytype) void {
        _ = angles;
        recordPosition(pos);
        fillMatrix(ctx, out);
    }

    pub fn func_800985AC(ctx: *zd.Ctx, pos: anytype, angles: anytype, out: anytype) void {
        _ = angles;
        recordPosition(pos);
        fillMatrix(ctx, out);
    }

    // The C tests nothing of the result, but casts it to short: a stub that
    // returns a wide value checks that the port narrows it the same way.
    pub fn vs_battle_clamp(ctx: *zd.Ctx, val: anytype, lo: anytype, hi: anytype) c_int {
        if (ctx.value(u1) == 1) return ctx.value(c_int);
        return std.math.clamp(@as(c_int, val), @as(c_int, lo), @as(c_int, hi));
    }
};
