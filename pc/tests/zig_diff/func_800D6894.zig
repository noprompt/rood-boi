//! zig_diff spec: func_800D6894 -> func_800D6894.func_800D6894 (5BF94.c).
//! Inputs: arg0 is a D_800F53B8_t whose unkD1C.unk30 points at a
//! D_800F53B8_t4 table entry; arg1 is a func_800D5780_t whose unk0 is a guest
//! pointer chosen so that unk0 + 4 * unk6 lands on a func_800D6894_t object
//! inside a 4 KB arena region (unk6 spans zero, negatives and edges). The
//! object's unk0 covers all 128 dispatch values, with the low 16 biased in.
//! The table's unk2 matches the object's (unk0 & 0x1FF) about 3/4 of the
//! time, so the equality is taken both ways and every switch case is reached.
//! Callees are recording stubs; func_800D5780 returns any c_int and may
//! write arg1's unkC, which the C never reads back.
const std = @import("std");
const zd = @import("zdiff");
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800D6894));

pub const classes = [_][:0]const u8{ "mismatch", "match-no-case", "match-case" };

pub const stubs = struct {
    pub fn func_800D5780(ctx: *zd.Ctx, p: anytype) c_int {
        if (ctx.value(u1) == 1) {
            const a: *v.func_800D5780_t = @ptrCast(@alignCast(p));
            a.unkC = ctx.value(i32);
        }
        return ctx.value(c_int);
    }
};

fn objOf(a1: *v.func_800D5780_t) *align(1) v.func_800D6894_t {
    const raw: isize = @intCast(psx.addr(psx.get(a1.unk0).?));
    return @ptrFromInt(@as(usize, @intCast(raw + 4 * @as(isize, a1.unk6))));
}

pub fn prepare(ctx: *zd.Ctx) Args {
    const a0 = ctx.alloc(v.D_800F53B8_t);
    const a1 = ctx.alloc(v.func_800D5780_t);
    const tbl = ctx.alloc(v.D_800F53B8_t4);
    const region: [*]u8 = ctx.allocBytes(4096, 16);
    const obj: *v.func_800D6894_t = @ptrCast(@alignCast(region + 2048));
    const obj_addr: isize = @intCast(@intFromPtr(obj));

    // The C reads the object at unk0 + 4 * unk6 (unk0 is a u32 guest pointer).
    const unk6: i16 = ctx.pick(i16, &.{ 0, 1, -1, 100, -100, 255, -255 });
    a1.unk6 = unk6;
    const raw: usize = @intCast(obj_addr - 4 * @as(isize, unk6));
    psx.put(&a1.unk0, @as(*u32, @ptrFromInt(raw)));

    // Dispatch value: half the time in 0..15 (the cases), otherwise any.
    obj.unk0 = if (ctx.chance(2))
        (@as(u16, ctx.range(u8, 0, 15)) << 9) | @as(u16, ctx.int(u9))
    else
        ctx.int(u16);
    obj.unk2 = ctx.int(u8);
    obj.unk3 = ctx.int(u8);

    psx.put(&a0.unkD1C.unk30, tbl);
    // The equality partner: usually the object's masked key, else edge values.
    tbl.unk2 = if (ctx.chance(4))
        ctx.pick(i16, &.{ -1, -512, 0, 511, 512, 0x7FFF, -32768 })
    else
        @intCast(obj.unk0 & 0x1FF);

    return .{ a0, a1 };
}

pub fn classify(args: Args) usize {
    const a0 = args[0].?;
    const a1 = args[1].?;
    const obj = objOf(a1);
    const tbl = psx.get(a0.unkD1C.unk30).?;
    if (@as(i32, obj.unk0 & 0x1FF) != @as(i32, tbl.unk2)) return 0;
    return if ((obj.unk0 >> 9) < 16) 2 else 1;
}
