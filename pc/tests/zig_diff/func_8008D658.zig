//! zig_diff spec: func_8008D658 -> func_8008D658.func_8008D658 (146C.c).
//! Inputs: a random _mpdRoomSectionA in the arena (the 16-bit state at unk8
//! is zero, one, or any i16, negative values included; the three callee
//! arguments and unk6 are edge or random i16s; unkB any byte). The callee
//! func_8008B764 returns the arena section object on some iterations and
//! NULL on others, so both sides of its test are reached. The sound calls
//! and func_8009291C are recording stubs; func_8009291C returns a value the C
//! discards.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008D658));

pub const classes = [_][:0]const u8{ "zero-found", "zero-null", "nonzero-found", "nonzero-null" };

/// The section object func_8008B764 hands back when it does not return NULL.
var sec3: ?*v._mpdRoomSection3 = null;
/// Whether func_8008B764 returns NULL in this iteration (set by prepare, the
/// same in both runs).
var want_null: bool = false;

pub const stubs = struct {
    pub fn vs_main_playSfxDefault(ctx: *zd.Ctx, a: anytype, b: anytype) void {
        _ = ctx;
        _ = a;
        _ = b;
    }

    pub fn func_8009291C(ctx: *zd.Ctx, a: anytype) c_int {
        _ = a;
        return ctx.value(c_int);
    }

    pub fn func_8008B764(ctx: *zd.Ctx, a: anytype, b: anytype, c: anytype) ?*v._mpdRoomSection3 {
        _ = ctx;
        _ = a;
        _ = b;
        _ = c;
        if (want_null) return null;
        return sec3;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg = ctx.alloc(v._mpdRoomSectionA);
    sec3 = ctx.alloc(v._mpdRoomSection3);
    want_null = ctx.chance(2);

    arg.unk0.unk0 = ctx.pick(i16, &.{ 0, -1, 32767, -32768 });
    arg.unk0.unk2 = ctx.pick(i16, &.{ 0, -1, 32767, -32768 });
    arg.unk0.unk4 = ctx.pick(i16, &.{ 0, -1, 32767, -32768 });
    arg.unk0.unk6 = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
    arg.unk0.unk8.s16 = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });
    if (ctx.chance(3)) arg.unk0.unk8.s16 = 0;
    arg.unk0.unkB = ctx.int(u8);
    return .{arg};
}

pub fn classify(args: Args) usize {
    const zero = args[0].?.unk0.unk8.s16 == 0;
    const null_case: usize = if (want_null) 1 else 0;
    return (if (zero) @as(usize, 0) else @as(usize, 2)) + null_case;
}
