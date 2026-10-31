//! zig_diff spec: func_800770FC -> func_800770FC.func_800770FC (146C.c).
//! Inputs: arg0 is unused by the C, so it is null or a fresh actor in the arena.
//! arg1 is any c_int, including values the i8 `index` field truncates (127, 128,
//! 255, 256, -129) and the int extremes. The populate call is a recording stub
//! that copies the fields the C sets into the arena (so a wrong field shows in
//! the state), sometimes rewrites dataAddr, and returns any int, which the C ignores.
//! Only fields the C writes are copied: the others of sp10 are stack garbage.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800770FC));

pub const classes = [_][:0]const u8{ "null-actor", "actor" };

pub const stubs = struct {
    pub fn vs_battle_populateDataSlot(ctx: *zd.Ctx, p: anytype) c_int {
        if (p) |raw| {
            const d: *v.vs_battle_objectData = @ptrCast(@alignCast(raw));
            const seen = ctx.alloc(v.vs_battle_objectData);
            seen.dataType = d.dataType;
            seen.index = d.index;
            seen.modelId = d.modelId;
            seen.actorId = d.actorId;
            if (ctx.value(u1) == 1) d.dataAddr = ctx.value(u32);
        }
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor: ?*v.vs_battle_actor = if (ctx.chance(3)) null else ctx.alloc(v.vs_battle_actor);
    const arg1 = ctx.pick(c_int, &.{
        0,
        1,
        -1,
        127,
        128,
        255,
        256,
        -129,
        std.math.maxInt(c_int),
        std.math.minInt(c_int),
    });
    return .{ actor, arg1 };
}

pub fn classify(args: Args) usize {
    return if (args[0] == null) 0 else 1;
}
