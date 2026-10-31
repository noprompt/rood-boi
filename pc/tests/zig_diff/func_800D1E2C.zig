//! zig_diff spec: func_800D1E2C -> func_800D1E2C.func_800D1E2C (5BF94.c).
//! Inputs: a D_800F54B8_t in the arena, never null because the C dereferences
//! it. unk0 and unk2 come from u8 edges (0, 1, 127, 128, 255) or any byte, and
//! the unk1_5 flag is random. A clear flag returns unk2 directly. A set flag
//! samples the curve with unk2 as curveId and unk0 as distance, and the stub
//! returns any c_int, so the u8 return narrows it.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
const psx = @import("common").psx;
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D1E2C));

pub const classes = [_][:0]const u8{ "flag-clear", "flag-set" };

pub const stubs = struct {
    pub fn vs_battle_sampleCurve(ctx: *zd.Ctx, curveId: anytype, distance: anytype) c_int {
        _ = curveId;
        _ = distance;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg = ctx.alloc(v.D_800F54B8_t);
    const edges = [_]u8{ 0, 1, 127, 128, 255 };
    arg.unk0 = ctx.pick(u8, &edges);
    arg.unk2 = ctx.pick(u8, &edges);
    psx.setBits(arg, "unk1_5", ctx.int(u1));
    return .{arg};
}

pub fn classify(args: Args) usize {
    return if (psx.getBits(args[0].?, "unk1_5") == 0) 0 else 1;
}
