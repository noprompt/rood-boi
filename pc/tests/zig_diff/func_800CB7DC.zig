//! zig_diff spec: func_800CB7DC -> func_800CB7DC.func_800CB7DC (5BF94.c).
//! Inputs: the global pointer D_800EB9B4 is null (a third of the runs) or
//! points at an arena object whose unk1 is 1, 0, 2 or 255. The stubs of
//! func_8007E1C0 rewrite unk1 and sometimes swap the global to a fresh
//! object, so a port that caches the pointer or unk1 across that call
//! diverges. The stubs return random values; the C ignores them.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CB7DC));

pub const classes = [_][:0]const u8{ "null", "unk1-one", "unk1-other" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const g = v.g.D_800EB9B4();
    if (ctx.chance(3)) {
        g.* = null;
        return .{};
    }
    const obj = ctx.alloc(v.D_800EB9B4_t);
    obj.unk1 = ctx.pick(u8, &.{ 0, 1, 2, 255 });
    g.* = obj;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const p = v.g.D_800EB9B4().* orelse return 0;
    return if (p.unk1 == 1) 1 else 2;
}

pub const stubs = struct {
    pub fn func_8007E1C0(ctx: *zd.Ctx, arg0: anytype) c_int {
        _ = arg0;
        const g = v.g.D_800EB9B4();
        if (ctx.value(u1) == 1) {
            if (g.*) |p| p.unk1 = ctx.value(u8);
        }
        if (ctx.value(u2) == 0 and g.* != null) {
            g.* = ctx.alloc(v.D_800EB9B4_t);
        }
        return ctx.value(c_int);
    }

    pub fn func_8007E0A8(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) c_int {
        _ = a;
        _ = b;
        _ = c;
        return ctx.value(c_int);
    }

    pub fn func_800CA97C(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) v.g.D_800EB9B4().* = null;
    }
};
