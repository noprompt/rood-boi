//! zig_diff spec: func_8007B938 -> func_8007B938.func_8007B938 (146C.c).
//! Inputs: one arena object that func_800CB66C returns and the C reads
//! `->unk0` from (its first 4 bytes). In one class unk0 is 1, which takes the
//! short-circuit; in the other it is 0, 2, 0x100, 0x8000_0000 or 0xFFFF_FFFF.
//! func_800C97BC may rewrite unk0 before the C reads it, and func_800CB45C
//! returns 0 or a nonzero int, so both sides of the `== 0` test are reached.
const std = @import("std");
const zd = @import("zdiff");
const c = @import("c_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B938));

pub const classes = [_][:0]const u8{ "unk0-is-one", "unk0-not-one" };

var obj: [*]u8 = undefined;
var mode: usize = 0;

fn setUnk0(val: u32) void {
    std.mem.writeInt(u32, obj[0..4], val, .little);
}

pub const stubs = struct {
    /// Can rewrite unk0 (the C reads it after this call).
    pub fn func_800C97BC(ctx: *zd.Ctx) void {
        if (ctx.value(u2) == 0) setUnk0(ctx.value(u32));
    }

    /// Never null: the C dereferences the result without a test.
    pub fn func_800CB66C(ctx: *zd.Ctx) ?*c.D_800F18EC_t {
        _ = ctx;
        return @ptrCast(@alignCast(obj));
    }

    /// Zero about one time in four, otherwise any value.
    pub fn func_800CB45C(ctx: *zd.Ctx) c_int {
        if (ctx.value(u2) == 0) return 0;
        return ctx.value(c_int);
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    obj = ctx.allocBytes(64, 16);
    mode = if (ctx.chance(2)) 0 else 1;
    if (mode == 0) {
        setUnk0(1);
    } else {
        setUnk0(ctx.pick(u32, &.{ 0, 2, 0x100, 0x8000_0000, 0xFFFF_FFFF }));
    }
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    return mode;
}
