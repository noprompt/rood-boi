//! zig_diff spec: func_800744B8 -> func_800744B8.func_800744B8 (146C.c).
//! Inputs: D_800F1910.unk0 points at one of two arena _mpdRoomSectionA objects.
//! Their keyOrSigil is zero or nonzero (both signs), and their unk10 sits at
//! the i16 edges, so unk10 + 0x3C0 wraps as a c_short. The object returned by
//! func_800CB66C has unk0 == 1 or not, and unk2 zero, negative or positive.
//! func_800CB45C returns 0..3. The stubs may repoint D_800F1910.unk0 to the
//! second object and rewrite the fields the C re-reads after each call.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800744B8));

pub const classes = [_][:0]const u8{ "keyed", "unkeyed-unk0-one", "unkeyed-unk2-nonzero", "unkeyed-unk2-zero" };

var obj_a: *v._mpdRoomSectionA = undefined;
var obj_b: *v._mpdRoomSectionA = undefined;
var state: *v.D_800F18EC_t = undefined;

pub const stubs = struct {
    pub fn func_800C97BC(ctx: *zd.Ctx) void {
        // The state update may move the battle room pointer the C re-reads.
        if (ctx.value(u2) == 0) psx.put(&v.g.D_800F1910().unk0, obj_b);
    }

    pub fn func_800CB66C(ctx: *zd.Ctx) ?*c.D_800F18EC_t {
        // The returned state's unk2 is rewritten by the callee, sometimes zero.
        state.unk2 = if (ctx.value(u2) == 0) 0 else ctx.value(i16);
        const p: *c.D_800F18EC_t = @ptrCast(state);
        return p;
    }

    pub fn func_800CB45C(ctx: *zd.Ctx) c_int {
        return @intCast(ctx.value(u2));
    }

    pub fn func_8008D5FC(ctx: *zd.Ctx, p: anytype) void {
        // The callee may change the room record it is given.
        const a: *v._mpdRoomSectionA = @ptrCast(@alignCast(p));
        if (ctx.value(u1) == 1) a.unk10 = ctx.value(i16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    obj_a = ctx.alloc(v._mpdRoomSectionA);
    obj_b = ctx.alloc(v._mpdRoomSectionA);
    state = ctx.alloc(v.D_800F18EC_t);
    psx.put(&v.g.D_800F1910().unk0, obj_a);
    for ([_]*v._mpdRoomSectionA{ obj_a, obj_b }) |o| {
        o.keyOrSigil = if (ctx.chance(2)) 0 else ctx.pick(i16, &.{ 1, -1, 0x7FFF, -0x8000 });
        o.unk10 = ctx.pick(i16, &.{ 0x7FFF, -0x8000, -0x3C0, -0x3C1, 0, 0x7FFC, -1 });
    }
    state.unk0 = if (ctx.chance(4)) 1 else ctx.pick(i16, &.{ 0, 2, -1 });
    state.unk2 = ctx.pick(i16, &.{ 0, 1, -1, 0x7FFF, -0x8000 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if (obj_a.keyOrSigil != 0) return 0;
    if (state.unk0 == 1) return 1;
    return if (state.unk2 != 0) 2 else 3;
}
