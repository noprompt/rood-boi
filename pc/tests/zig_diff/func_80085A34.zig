//! zig_diff spec: func_80085A34 -> func_80085A34.func_80085A34 (146C.c).
//! Inputs: an object with unk40 zero or locked, unk2 at 0xFF or not, unk3 at 6
//! or not, unk14/unk18 zero or not, and unk1C either zero, all-zero digits
//! within the nine base-4 steps (including the sign bit alone), or a first
//! nonzero digit at each position 0-8 with digit 1, 2 or 3. Nothing else is
//! read, and the C calls nothing, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_80085A34));

pub const classes = [_][:0]const u8{
    "locked",
    "not-six",
    "word-zero-kept",
    "word-zero-idle",
    "digit-1",
    "digit-2",
    "digit-3",
    "no-digit",
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.func_80085A34_t);

    obj.unk40 = if (ctx.chance(5)) ctx.pick(i32, &.{ 1, -1, 0x100, std.math.minInt(i32) }) else 0;
    obj.unk2 = ctx.pick(u8, &.{ 0xFF, 0xFE, 0 });
    obj.unk3 = if (ctx.chance(4)) ctx.int(u8) else 6;
    obj.unk14 = if (ctx.chance(2)) 0 else ctx.int(i32);
    obj.unk18 = if (ctx.chance(2)) 0 else ctx.int(i32);

    const shape = ctx.range(u8, 0, 9);
    const word: u32 = switch (shape) {
        0 => 0,
        1 => if (ctx.chance(2)) 0x8000_0000 else ctx.range(u32, 1, 0x3FFF) << 18,
        else => blk: {
            const k = ctx.range(u32, 0, 8);
            const sh: u5 = @intCast(2 * k);
            const d = ctx.range(u32, 1, 3);
            break :blk (ctx.int(u32) << (sh + 2)) | (d << sh);
        },
    };
    obj.unk1C = @bitCast(word);

    return .{obj};
}

pub fn classify(args: Args) usize {
    const a = args[0].?;
    if (a.unk40 != 0) return 0;
    if (a.unk3 != 6) return 1;
    if (a.unk1C == 0) return if ((a.unk14 | a.unk18) == 0) 3 else 2;
    var w: u32 = @bitCast(a.unk1C);
    for (0..9) |_| {
        switch (w & 3) {
            1 => return 4,
            2 => return 5,
            3 => return 6,
            else => {},
        }
        w /= 4;
    }
    return 7;
}
