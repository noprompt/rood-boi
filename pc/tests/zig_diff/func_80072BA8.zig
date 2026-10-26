//! zig_diff spec: func_80072BA8 -> func_80072BA8.func_80072BA8 (146C.c).
//! Inputs: a quarter of the runs use action 0 (the setup path: a six-limb loop
//! whose part comes from a stub that is zero one time in four and otherwise any
//! c_int, so both sides of `part >= 0` are equal and both signs occur). The other
//! runs use action 1..255 whose header flags pick a category 0..15; each of the
//! three per-category tables is zero or nonzero (nonzero as 1, 0x80 or 0xFF, so
//! the sign bit is seen with and without other bits), which selects all six
//! dispatch paths. The func_800A1108 stub fills the whole state it is given, and
//! func_800C06E0 sometimes moves D_800F19CC to a second block the C then uses.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80072BA8));

var alt_block: ?*v.D_800F19CC_t = null;

pub const classes = [_][:0]const u8{
    "action0",
    "no-table",
    "b-only",
    "a-only-c0",
    "a-only-c1",
    "a-b-c0",
    "a-b-c1",
};

pub const stubs = struct {
    /// Fills the state the C passes in (its pad is read back).
    pub fn func_800A1108(ctx: *zd.Ctx, id: anytype, out: anytype) c_int {
        _ = id;
        const opt: ?*anyopaque = out;
        const bytes: [*]u8 = @ptrCast(opt.?);
        for (0..16) |i| bytes[i] = ctx.value(u8);
        return ctx.value(c_int);
    }

    /// The part index: zero one time in four (the C's `part >= 0` equal case),
    /// otherwise any value, negative about half the time.
    pub fn func_800A152C(ctx: *zd.Ctx, actorId: anytype, limb: anytype, kind: anytype) c_int {
        _ = actorId;
        _ = limb;
        _ = kind;
        if (ctx.value(u8) < 64) return 0;
        return ctx.value(c_int);
    }

    /// Sometimes repoints D_800F19CC at a second block; the C re-reads the global.
    pub fn func_800C06E0(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g.D_800F19CC().* = alt_block.?;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    v.g.D_800F19CC().* = ctx.alloc(v.D_800F19CC_t);
    alt_block = ctx.alloc(v.D_800F19CC_t);

    const action: c_int = if (ctx.chance(4)) 0 else ctx.range(c_int, 1, 255);
    if (action != 0) {
        const cat = ctx.range(u4, 0, 15);
        const act = &v.g.actions()[@intCast(action)];
        act._bits_2[0] = (@as(u8, cat) << 4) | @as(u8, ctx.int(u4));
        const tables = [3][*]u8{ v.g.D_800E8184(), v.g.D_800E8194(), v.g.D_800E81C4() };
        for (tables) |t| {
            t[cat] = if (ctx.chance(2)) 0 else ctx.edge(u8, &.{ 1, 0x80, 0xFF });
        }
    }
    return .{action};
}

pub fn classify(args: Args) usize {
    const action = args[0];
    if (action == 0) return 0;
    const cat: usize = v.g.actions()[@intCast(action)]._bits_2[0] >> 4;
    const a = v.g.D_800E8184()[cat] != 0;
    const b = v.g.D_800E8194()[cat] != 0;
    const c = v.g.D_800E81C4()[cat] != 0;
    if (!a and !b) return 1;
    if (!a) return 2;
    if (!b) return if (c) 4 else 3;
    return if (c) 6 else 5;
}
