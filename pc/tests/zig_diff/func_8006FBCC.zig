//! zig_diff spec: func_8006FBCC -> func_8006FBCC.func_8006FBCC (146C.c).
//! Inputs: any arg0, and a D_800F19CC object in the arena whose targetActor is
//! 0, 1, 15 (each matches a loop index) or 16/255 (never matches). The
//! func_800A0BE0 results are random words, so every index reaches all four
//! branch combinations of the && chain. func_8009E5C4 sometimes rewrites
//! targetActor, which the C re-reads on each pass of the loop.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006FBCC));

pub const classes = [_][:0]const u8{ "target-in-loop", "target-out-of-loop" };

pub const stubs = struct {
    /// The C's flag word: bit 24 and bit 0 are both tested, so random words
    /// give every combination.
    pub fn func_800A0BE0(ctx: *zd.Ctx, i: anytype) c_uint {
        _ = i;
        return ctx.value(c_uint);
    }

    /// Sometimes rewrites the target the loop compares against.
    pub fn func_8009E5C4(ctx: *zd.Ctx, i: anytype) void {
        _ = i;
        if (ctx.value(u1) == 1) {
            const d = v.g.D_800F19CC().*.?;
            d.unk8.unk4.unk0.targetActor = ctx.value(u8);
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.D_800F19CC_t);
    obj.unk8.unk4.unk0.targetActor = ctx.pick(u8, &.{ 0, 1, 15, 16, 255 });
    v.g.D_800F19CC().* = obj;
    return .{ctx.int(c_int)};
}

pub fn classify(args: Args) usize {
    _ = args;
    const obj = v.g.D_800F19CC().*.?;
    return if (obj.unk8.unk4.unk0.targetActor < 16) 0 else 1;
}
