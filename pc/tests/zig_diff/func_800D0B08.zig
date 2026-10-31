//! zig_diff spec: func_800D0B08 -> func_800D0B08.func_800D0B08 (5BF94.c).
//! The C forwards its argument to func_800CFE98 with the address of
//! D_800F5310. Inputs: an arena object for arg0, or null (the C does not
//! test it, so the callee sees null too). The callee stub writes the
//! SVECTOR it is passed and, when given one, the object's unk0 and unk4,
//! so a port that reads them back after the call is caught.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D0B08));

pub const classes = [_][:0]const u8{ "null-arg", "object-arg" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.func_800CFE98_t);
    if (ctx.chance(4)) return .{null};
    return .{obj};
}

pub fn classify(args: Args) usize {
    return if (args[0] == null) 0 else 1;
}

pub const stubs = struct {
    pub fn func_800CFE98(ctx: *zd.Ctx, sv: anytype, obj: anytype) void {
        const s: *v.SVECTOR = @ptrCast(@alignCast(sv));
        s.vx = ctx.value(i16);
        s.vy = ctx.value(i16);
        if (obj != null) {
            const o: *v.func_800CFE98_t = @ptrCast(@alignCast(obj));
            o.unk0 = ctx.value(i32);
            o.unk4 = ctx.value(i32);
        }
    }
};
