//! zig_diff spec: func_8007CB84 -> func_8007CB84.func_8007CB84 (146C.c).
//! Inputs: any c_int index and wepId, biased toward the i8 and i16 truncation
//! edges of objData.index and objData.modelId (0, -1, 127/128, 255/256,
//! 32767/32768, 65536). The C has no branches; it fills four fields of a
//! stack vs_battle_objectData and makes one call with its address. The stub
//! copies the four fields the C sets into an arena record (the C leaves the
//! other fields uninitialised, so they are not copied), which makes the
//! call's content part of the compared state. Its return value is ignored
//! by the C and comes from ctx.value.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007CB84));

const Record = struct {
    dataType: u8,
    index: i8,
    modelId: i16,
    actorId: u8,
};

// The arena record the populateDataSlot stub writes the call's fields into.
var rec: *Record = undefined;

pub const classes = [_][:0]const u8{ "index-negative", "index-nonnegative" };

pub const stubs = struct {
    pub fn vs_battle_populateDataSlot(ctx: *zd.Ctx, p: anytype) c_int {
        const o: *const v.vs_battle_objectData = @ptrCast(@alignCast(p));
        rec.dataType = o.dataType;
        rec.index = o.index;
        rec.modelId = o.modelId;
        rec.actorId = o.actorId;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    rec = ctx.alloc(Record);
    const edges = [_]c_int{ 0, -1, 1, 127, 128, -128, -129, 255, 256, 32767, 32768, -32768, 65536 };
    const index = ctx.pick(c_int, &edges);
    const wepId = ctx.pick(c_int, &edges);
    return .{ index, wepId };
}

pub fn classify(args: Args) usize {
    return if (args[0] < 0) 0 else 1;
}
