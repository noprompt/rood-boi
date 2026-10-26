//! zig_diff spec: func_8006FCBC -> func_8006FCBC.func_8006FCBC (146C.c).
//! Inputs: the global D_800F19CC always points at a random arena
//! D_800F19CC_t (the C never tests it, so it must be non-null), and its
//! unk854[0].unk4.unk0.targetActor is random, so it covers 0, 255 and the
//! rest of the u8 range. The C has no branches; its value edges are the
//! targetActor byte and the random int that func_800A152C returns.
//! func_800A152C may rewrite that targetActor field (the C reads it again
//! for the second call's argument), and func_8006C4A4 may write _cameraMode.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006FCBC));

pub const classes = [_][:0]const u8{ "target-zero", "target-nonzero" };

pub const stubs = struct {
    /// Lookup: returns any int, and may change the target the C reads back.
    pub fn func_800A152C(ctx: *zd.Ctx, actorId: anytype, a: anytype, b: anytype) c_int {
        _ = actorId;
        _ = a;
        _ = b;
        if (ctx.value(u1) == 1) {
            const d = v.g.D_800F19CC().*.?;
            d.unk854[0].unk4.unk0.targetActor = ctx.value(u8);
        }
        return ctx.value(c_int);
    }

    /// Void callee: may write _cameraMode.
    pub fn func_8006C4A4(ctx: *zd.Ctx, a: anytype, b: anytype) void {
        _ = a;
        _ = b;
        if (ctx.value(u1) == 1) v.g._cameraMode().* = ctx.value(u32);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const d = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = d;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const d = v.g.D_800F19CC().*.?;
    return if (d.unk854[0].unk4.unk0.targetActor == 0) 0 else 1;
}
