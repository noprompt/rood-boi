//! zig_diff spec: func_8007B834 -> func_8007B834.func_8007B834 (146C.c).
//! Inputs: one arena D_800F18EC_t whose unk0 is 0, 1, 2 or any other value
//! (the C skips the three calls only when unk0 == 1). The four callees are
//! recording stubs. func_800C97BC may rewrite unk0 before the C reads it, so
//! a port that reads unk0 before that call still differs. func_800CB66C always
//! returns the valid object: the C dereferences it without a null test.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B834));

pub const classes = [_][:0]const u8{ "unk0-is-one", "unk0-other" };

var obj: *v.D_800F18EC_t = undefined;

pub const stubs = struct {
    /// Rewrites unk0 sometimes: the C reads it back after this call.
    pub fn func_800C97BC(ctx: *zd.Ctx) void {
        if (ctx.value(u1) == 1) obj.unk0 = ctx.value(@TypeOf(obj.unk0));
    }

    /// Never null: the C dereferences the result without a test.
    pub fn func_800CB66C(ctx: *zd.Ctx) ?*v.D_800F18EC_t {
        _ = ctx;
        return obj;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    obj = ctx.alloc(v.D_800F18EC_t);
    const T = @TypeOf(obj.unk0);
    obj.unk0 = ctx.pick(T, &.{ 0, 1, 2 });
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return if (obj.unk0 == 1) 0 else 1;
}
