//! zig_diff spec: func_8008E938 -> func_8008E938.func_8008E938 (146C.c).
//! Inputs: the room's section B present or absent; its five unk0 words all
//! equal (masked to 24 bits zero or not, with and without the sign bit) or
//! one of unk0[1..4] differing; the unk48 pair zero or not; a collision map
//! present or absent, with edge width and height. func_8008EB30 may rewrite
//! unk0 and zero unk48, which the C tests after the call.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008E938));

pub const classes = [_][:0]const u8{ "no-section", "differs", "equal-masked-zero", "equal-masked-set" };

pub const stubs = struct {
    pub fn func_8008EB30(ctx: *zd.Ctx, p: anytype) void {
        const words: *[5]i32 = @ptrCast(@alignCast(p));
        const base: [*]u8 = @ptrCast(p);
        if (ctx.value(u1) == 1) words[ctx.value(u8) % 5] = ctx.value(i32);
        const s0: *i32 = @ptrCast(@alignCast(base + 0x48));
        const s1: *i32 = @ptrCast(@alignCast(base + 0x4C));
        const m = ctx.value(u2);
        if (m == 1) {
            s0.* = 0;
            s1.* = 0;
        } else if (m == 2) {
            s0.* = ctx.value(i32);
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const room = v.g.vs_battle_roomData();
    const b = ctx.alloc(v._mpdRoomSectionB);

    // Section B present most of the time.
    psx.put(&room.sectionB, if (ctx.chance(8)) null else b);

    // unk0: a word pattern, all five equal or one of [1..4] differing.
    const w: i32 = @bitCast(ctx.pick(u32, &.{ 0, 1, 0x80000000, 0xFF000000, 0x00FF0000, 0x80000001, 0xFFFFFFFF, 0x00FFFFFF }));
    for (&b.unk0) |*x| x.* = w;
    const k = ctx.range(u8, 0, 4);
    if (k != 0) b.unk0[k] = w +% 1;

    // unk48 pair: zero or not, so the both-zero branch is taken sometimes.
    const zero0 = ctx.chance(2);
    b.unk48[0].s32 = if (zero0) 0 else ctx.pick(i32, &.{ 1, -1, 0x10000, 0x7FFF, -0x80000000 });
    b.unk48[1].s32 = if (zero0 and ctx.chance(2)) 0 else ctx.pick(i32, &.{ 1, -1, 0x10000, 0x7FFF, -0x80000000 });

    // Collision map: absent, or edge sizes.
    const cm = ctx.alloc(v._mpdRoomCollisionMapSection);
    cm.width = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 0x20 });
    cm.height = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768, 0x20 });
    psx.put(&room.collisionMapSection, if (ctx.chance(4)) null else cm);

    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const b = psx.get(v.g.vs_battle_roomData().sectionB) orelse return 0;
    for (b.unk0[1..]) |x| {
        if (x != b.unk0[0]) return 1;
    }
    return if ((b.unk0[0] & 0xFFFFFF) == 0) 2 else 3;
}
