//! zig_diff spec: func_80078248 -> func_80078248.func_80078248 (146C.c).
//! Inputs: a D_800F19CC_t object in the arena, set as the global pointer. The
//! unit's 2984 flag is zero or any i32 (negatives included), the target
//! actor is zero or nonzero, and the 298E hit counter sits at 0x1D, 0x1E,
//! 0x1F or 0xFF so the increment reaches the 0x1F bound and wraps at 0xFF.
//! func_800C58F8 is a recording stub that writes its byte argument (the C
//! reads it back through unk298C) and returns zero or nonzero.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80078248));

pub const classes = [_][:0]const u8{ "inactive", "target-below-31", "target-reaches-31", "no-target" };

pub const stubs = struct {
    pub fn func_800C58F8(ctx: *zd.Ctx, p: anytype) c_int {
        // The callee may rewrite the byte it is given; the C reads it back.
        p[0] = ctx.value(u8);
        if (ctx.value(u1) == 0) return 0;
        return ctx.value(c_int) | 1;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = obj;
    obj.unk2984 = if (ctx.chance(4)) 0 else ctx.pick(i32, &.{ 1, -1, 0x7fffffff, -0x80000000 });
    obj.unk8.unk4.unk0.targetActor = if (ctx.chance(3)) 0 else ctx.edge(u8, &.{ 1, 0x80, 0xFF });
    obj.unk298E = ctx.pick(u8, &.{ 0x1D, 0x1E, 0x1E, 0x1F, 0xFF });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const obj = v.g.D_800F19CC().*.?;
    if (obj.unk2984 == 0) return 0;
    if (obj.unk8.unk4.unk0.targetActor == 0) return 3;
    return if (obj.unk298E == 0x1E) 2 else 1;
}
