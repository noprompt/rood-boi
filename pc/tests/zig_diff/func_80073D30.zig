//! zig_diff spec: func_80073D30 -> func_80073D30.func_80073D30 (146C.c).
//! Inputs: a room section and a func_8006EBF8_t (random bytes), and a battle
//! actor index 0-15 whose table entry prepare sets to an actor with a random
//! stats block, so targetLimb (the stats' unk36) has its sign bit set about
//! half the time. Either pointer argument may alias the D_800F19CC request
//! block: the C stores into the request before it reads arg1 and arg0, so a
//! port that reorders those accesses differs. func_80085B10 is a stub that
//! rewrites the room section's unk6 (the C reads it again after the call)
//! and a request field.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80073D30));

pub const classes = [_][:0]const u8{ "limb-low", "limb-high", "arg1-aliases-request", "arg0-aliases-request" };

var room_ref: ?*v._mpdRoomSectionA = null;

pub const stubs = struct {
    pub fn func_80085B10(ctx: *zd.Ctx, effect: c_int, shown: anytype, req: anytype, flag: c_int) void {
        _ = effect;
        _ = shown;
        _ = flag;
        if (ctx.value(u1) == 1) {
            const r: *v.D_800F19CC_t2 = @ptrCast(@alignCast(req.?));
            r.unk4A = ctx.value(u16);
        }
        if (ctx.value(u1) == 1) {
            if (room_ref) |rm| rm.unk0.unk6 = ctx.value(i16);
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const request = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = request;

    const room = ctx.alloc(v._mpdRoomSectionA);
    room.unk0.unk6 = ctx.pick(i16, &.{ 0, -6, 32761, 32762, -32768, 32767 });
    const feed = ctx.alloc(v.func_8006EBF8_t);

    const stats = ctx.alloc(v.vs_battle_actor2);
    const actor = ctx.alloc(v.vs_battle_actor);
    psx.put(&actor.stats, stats);
    const target = ctx.range(c_int, 0, 15);
    v.g.vs_battle_actors()[@intCast(target)] = actor;

    var arg0: ?*v._mpdRoomSectionA = room;
    var arg1: ?*v.func_8006EBF8_t = feed;
    if (ctx.chance(4)) arg1 = @ptrCast(@alignCast(request));
    if (ctx.chance(4)) arg0 = @ptrCast(@alignCast(request));
    room_ref = arg0;

    return .{ arg0, arg1, target };
}

pub fn classify(args: Args) usize {
    const request = v.g.D_800F19CC().*.?;
    if (args[1]) |f| {
        if (@intFromPtr(f) == @intFromPtr(request)) return 2;
    }
    if (args[0]) |r| {
        if (@intFromPtr(r) == @intFromPtr(request)) return 3;
    }
    const actor = v.g.vs_battle_actors()[@intCast(args[2])].?;
    const stats = psx.get(actor.stats).?;
    return if (psx.getBits(stats, "unk36") >= 128) 1 else 0;
}
