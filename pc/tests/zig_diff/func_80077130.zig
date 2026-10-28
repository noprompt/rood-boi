//! zig_diff spec: func_80077130 -> func_80077130.func_80077130 (146C.c).
//! Inputs: an actor in the arena whose unk48 slots are arena blocks or null
//! (the actor may be null only when wepId is 0 or 0xFF, where the C never
//! reads it); wepId at 0, 1, 2, -1, 254, 255, 256 and the int extremes; isShield
//! at 0, 1, -1 and 2 (-1 is the sign-bit nonzero case, 2 reads one slot past
//! unk48); actorId around the actorId * 2 wrap; material at 0, 1, 255, 256 and -1.
//! The populate stub copies the fields of the objectData it receives into a
//! sink at the end of the arena, so a wrong slot, index, material or call is
//! visible in the state comparison.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80077130));

pub const classes = [_][:0]const u8{ "no-weapon", "no-weapon-id", "weapon-body", "weapon-shield" };

pub const stubs = struct {
    pub fn vs_battle_populateDataSlot(ctx: *zd.Ctx, p: anytype) c_int {
        const o: *const v.vs_battle_objectData = if (@typeInfo(@TypeOf(p)) == .optional)
            @ptrCast(@alignCast(p.?))
        else
            @ptrCast(@alignCast(p));
        const out = zd.zdiff_arena[zd.arena_size - 16 ..];
        out[0] = o.dataType;
        out[1] = @bitCast(o.index);
        std.mem.writeInt(u16, out[2..4], @bitCast(o.modelId), .little);
        std.mem.writeInt(u32, out[4..8], o.unk4.raw, .little);
        out[8] = o.actorId;
        out[9] = o.unk11;
        out[10] = o.material;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const actor = ctx.alloc(v.vs_battle_actor);
    for (0..2) |i| {
        psx.put(&actor.unk48[i], if (ctx.chance(6)) null else ctx.alloc(v.vs_battle_actor4));
    }
    const wepId = ctx.pick(c_int, &.{ 0, 1, 2, -1, 254, 255, 256, -256, 0x7FFFFFFF, -2147483648 });
    const isShield = ctx.edge(c_int, &.{ 0, 1, -1, 2 });
    const actorId = ctx.pick(c_int, &.{ 0, 1, -1, 0x3FFFFFFF, 0x40000000, 0x7FFFFFFF, -2147483648 });
    const material = ctx.pick(c_int, &.{ 0, 1, 255, 256, -1 });
    const live = wepId != 0 and wepId != 0xFF;
    const actorArg: ?*v.vs_battle_actor = if (live or !ctx.chance(3)) actor else null;
    return .{ actorArg, actorId, wepId, isShield, material };
}

pub fn classify(args: Args) usize {
    if (args[2] == 0xFF) return 0;
    if (args[2] == 0) return 1;
    return if (args[3] == 0) 2 else 3;
}
