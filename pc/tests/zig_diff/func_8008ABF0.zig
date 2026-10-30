//! zig_diff spec: func_8008ABF0 -> func_8008ABF0.func_8008ABF0 (146C.c).
//! Inputs: the room record active or not (unk0 == 1 most of the time), its
//! unk2 room id matching arg0 or not (edge values included), and its
//! geometrySection null, an arena block, or a guest address with the sign bit
//! set or clear. The three callees are recording stubs; func_80091378 and
//! func_80092A18 can replace or clear geometrySection before the C re-reads
//! it, so a port that caches the pointer early differs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8008ABF0));

pub const classes = [_][:0]const u8{
    "not-active",
    "wrong-room",
    "match-null-geometry",
    "match-geometry-low",
    "match-geometry-sign",
};

pub const stubs = struct {
    pub fn func_80091378(ctx: *zd.Ctx) void {
        const r = v.g.vs_battle_roomData();
        if (ctx.value(u1) == 1) psx.put(&r.geometrySection, @as(?*i32, null));
    }

    pub fn func_80092A18(ctx: *zd.Ctx) void {
        const r = v.g.vs_battle_roomData();
        switch (ctx.value(u2)) {
            0 => psx.put(&r.geometrySection, @as(?*i32, null)),
            1 => psx.put(&r.geometrySection, @as(*i32, @ptrFromInt(0x8000_0000 + 4 * @as(usize, ctx.value(u8))))),
            else => {},
        }
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const r = v.g.vs_battle_roomData();

    r.unk0 = if (ctx.chance(5)) ctx.pick(u8, &.{ 0, 2, 255 }) else 1;
    r.unk2 = ctx.pick(i16, &.{ 0, 1, -1, 32767, -32768 });

    const arg0: c_int = if (ctx.chance(3))
        @as(c_int, r.unk2)
    else
        ctx.pick(c_int, &.{ 0, 1, -1, 65537, -65536, 32767, -32768 });

    switch (ctx.range(u8, 0, 3)) {
        0 => psx.put(&r.geometrySection, @as(?*i32, null)),
        1 => psx.put(&r.geometrySection, ctx.alloc(i32)),
        2 => psx.put(&r.geometrySection, @as(*i32, @ptrFromInt(0x8000_0000 + 4 * @as(usize, ctx.range(u16, 0, 0x3FFF))))),
        else => psx.put(&r.geometrySection, @as(*i32, @ptrFromInt(0xC000_0000 + 4 * @as(usize, ctx.range(u16, 0, 0x3FFF))))),
    }

    return .{arg0};
}

pub fn classify(args: Args) usize {
    const r = v.g.vs_battle_roomData();
    if (r.unk0 != 1) return 0;
    if (@as(c_int, r.unk2) != args[0]) return 1;
    const raw = psx.rawOf(r.geometrySection);
    if (raw == 0) return 2;
    if (raw & 0x8000_0000 != 0) return 4;
    return 3;
}
