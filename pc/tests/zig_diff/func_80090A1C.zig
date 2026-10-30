//! zig_diff spec: func_80090A1C -> func_80090A1C.func_80090A1C (146C.c).
//! Inputs: a random D_800F1DD4_t output block; the room's sectionB either
//! null (the rand % 4096 branch) or a fresh _mpdRoomSectionB in the arena with
//! random 16-bit offsets and nonzero divisors (rand() % divisor would fault on
//! zero, so divisors are never 0; -1, 1 and the i16 extremes are common).
//! rand is a recording stub returning non-negative values, as the real rand
//! does, so the modulo results match the C's ranges.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80090A1C));

pub const classes = [_][:0]const u8{ "no-section", "section-nonnegative-offset", "section-negative-offset" };

pub const stubs = struct {
    pub fn rand(ctx: *zd.Ctx) c_int {
        return @intCast(ctx.value(u31));
    }
};

/// A nonzero divisor: rand() % 0 would fault in the C.
fn divisor(ctx: *zd.Ctx) i16 {
    if (ctx.chance(2)) return ctx.edge(i16, &.{ 1, -1, 2, 3, 512, 4096, 32767, -32768 });
    var d = ctx.int(i16);
    if (d == 0) d = 1;
    return d;
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const out = ctx.alloc(v.D_800F1DD4_t);
    const room = v.g.vs_battle_roomData();
    if (ctx.chance(3)) {
        psx.put(&room.sectionB, null);
    } else {
        const sb = ctx.alloc(v._mpdRoomSectionB);
        sb.unk48[0].s16[0] = ctx.int(i16);
        sb.unk48[0].s16[1] = ctx.int(i16);
        sb.unk48[1].s16[0] = divisor(ctx);
        sb.unk48[1].s16[1] = divisor(ctx);
        psx.put(&room.sectionB, sb);
    }
    return .{out};
}

pub fn classify(args: Args) usize {
    _ = args;
    const sb = psx.get(v.g.vs_battle_roomData().sectionB) orelse return 0;
    return if (sb.unk48[0].s16[0] < 0) 2 else 1;
}
