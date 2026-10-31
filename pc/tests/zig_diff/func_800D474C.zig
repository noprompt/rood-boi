//! zig_diff spec: func_800D474C -> func_800D474C.func_800D474C (5BF94.c).
//! Inputs: one D_800F53B8_t in the arena with random bytes, its unkA either 0 or
//! random. The C has no branches, so the value edges are the stored result and the
//! return value. The callee func_800D5198 is a recording stub: it writes the fields a
//! real callee may change (unk8, the unk14_8 bitfield) and returns any u16 the C stores
//! into unkA. Its call trace, the state at the call and the return value (always 1)
//! are compared.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D474C));

pub const classes = [_][:0]const u8{ "unkA-zero", "unkA-nonzero" };

pub const stubs = struct {
    pub fn func_800D5198(ctx: *zd.Ctx, p: anytype) u16 {
        const a: *v.D_800F53B8_t = @ptrCast(@alignCast(p.?));
        a.unk8 = ctx.value(u8);
        psx.setBits(a, "unk14_8", ctx.value(u3));
        return ctx.value(u16);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.D_800F53B8_t);
    obj.unkA = ctx.int(u16);
    if (ctx.chance(2)) obj.unkA = 0;
    return .{obj};
}

pub fn classify(args: Args) usize {
    return if (args[0].?.unkA == 0) 0 else 1;
}
