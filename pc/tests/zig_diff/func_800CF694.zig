//! zig_diff spec: func_800CF694 -> func_800CF694.func_800CF694 (5BF94.c).
//! Inputs: a random D_800F53B8_t owner in the arena whose head link
//! (unkD1C.unk34) is either null or points at a random arena node, and an
//! arg2 that is 0, -1, 1 or the int extremes. The C allocates a node through
//! vs_main_allocHeapR (a stub returning an arena block of the requested
//! size), links it in front of the old head, stores the renderer and clears
//! unk8, then calls the renderer. The renderer is a spec function that reads
//! next, renderer, unk8, its first two arguments and writes unk8 from them,
//! so a store moved past the call, a changed argument, or a wrong return
//! value shows up in the final state. The C has no data branches of its own;
//! the only branches are inside the unit's psx_addr helper (the above-4GB
//! fatal test cannot be reached, since the arena lies below 4GB) and must be
//! waived by the checker's id if it reports them.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CF694));

pub const classes = [_][:0]const u8{ "head-null", "head-set" };

var head_null: bool = false;

pub const stubs = struct {
    pub fn vs_main_allocHeapR(ctx: *zd.Ctx, size: anytype) ?*anyopaque {
        return @ptrCast(ctx.allocBytes(size, 16));
    }
};

fn renderer(obj: [*c]c.func_800D4910_t, a: c.u_int, b: c_int) callconv(.c) c_int {
    const o: *v.func_800D4910_t = @ptrCast(@alignCast(obj));
    const seen = @intFromPtr(o.next) +% @intFromPtr(o.renderer) +% @intFromPtr(o.unk8) +%
        @as(usize, a) +% @as(usize, @as(u32, @bitCast(b)));
    o.unk8 = @ptrFromInt(seen +% 7);
    return b;
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const owner = ctx.alloc(v.D_800F53B8_t);
    const old: ?*v.func_800D4910_t = if (ctx.chance(3)) null else ctx.alloc(v.func_800D4910_t);
    psx.put(&owner.unkD1C.unk34, old);
    head_null = old == null;
    return .{ owner, &renderer, ctx.pick(c_int, &.{ 0, -1, 1, 0x7fff_ffff, -0x8000_0000 }) };
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (head_null) 0 else 1;
}
