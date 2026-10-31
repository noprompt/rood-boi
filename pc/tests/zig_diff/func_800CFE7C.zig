//! zig_diff spec: func_800CFE7C -> func_800CFE7C.func_800CFE7C (5BF94.c).
//! Inputs: one func_800CFE98_t in the arena. Its words keep the random fill,
//! so every store is visible; a quarter of the runs preset unk0, unk8 and
//! unk10 to 0x1000 so the classes differ. The C has no branches, no calls
//! and no comparisons, so the value edges are the random words themselves
//! (any i32 pattern, including the sign bit and zero).
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CFE7C));

pub const classes = [_][:0]const u8{ "random", "preset" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.func_800CFE98_t);
    if (ctx.chance(4)) {
        obj.unk0 = 0x1000;
        obj.unk8 = 0x1000;
        obj.unk10 = 0x1000;
    }
    return .{obj};
}

pub fn classify(args: Args) usize {
    const obj = args[0].?;
    return if (obj.unk0 == 0x1000 and obj.unk8 == 0x1000) 1 else 0;
}
