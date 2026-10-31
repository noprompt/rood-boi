//! zig_diff spec: func_800CE714 -> func_800CE714.func_800CE714 (5BF94.c).
//! Inputs: a D_800F53B8_t2 and a D_800F53B8_t in the arena. The four source
//! pointers (unk0..unkC) name fresh D_800F53B8_t3 objects, which the C reads
//! without a null test, so they are always valid. Random bytes fill the
//! rest, and the i32/u8 source fields take edge values (sign bit, byte and
//! halfword wrap). The unk1C pointer is copied raw, never dereferenced, so it
//! is null or an arena object. Two aliasing modes are also built: unk0 names
//! arg1 itself, and unk4 names arg1's unkD1C block, so the C's store order
//! before the reads is observable. The C makes no calls, so there are no stubs.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_800CE714));

pub const classes = [_][:0]const u8{ "distinct", "alias-arg1", "alias-unkD1C" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const arg0 = ctx.alloc(v.D_800F53B8_t2);
    const arg1 = ctx.alloc(v.D_800F53B8_t);

    // The four targets the C dereferences (psx_get(arg0->unkN)->unk0).
    const t0 = ctx.alloc(v.D_800F53B8_t3);
    const t1 = ctx.alloc(v.D_800F53B8_t3);
    const t2 = ctx.alloc(v.D_800F53B8_t3);
    const t3 = ctx.alloc(v.D_800F53B8_t3);

    const mode = ctx.range(u8, 0, 7);
    arg0.unk0.raw = psx.addr(t0);
    arg0.unk4.raw = psx.addr(t1);
    arg0.unk8.raw = psx.addr(t2);
    arg0.unkC.raw = psx.addr(t3);
    if (mode == 0) arg0.unk0.raw = psx.addr(arg1);
    if (mode == 1) arg0.unk4.raw = psx.addr(arg1) + 0xD1C;

    // Copied raw into arg1->previous; never dereferenced.
    arg0.unk1C.raw = if (ctx.chance(4)) 0 else psx.addr(ctx.alloc(v.D_800F53B8_t));

    // Truncated on the way to u8/u16 fields: the sign bit and wrap matter.
    arg0.unk10 = ctx.pick(i32, &.{ 0, 1, -1, 255, 256, -256, 0x7FFF_FFFF, -0x8000_0000 });
    arg0.unk14.raw = ctx.pick(u32, &.{ 0, 0xFFFF_FFFF, 0x8000_0000, 0x1234 });
    arg0.unk18 = ctx.pick(i32, &.{ 0, 1, -1, 65535, 65536, -65536, 0x7FFF_FFFF, -0x8000_0000 });
    arg0.unk20 = ctx.pick(u8, &.{ 0, 1, 127, 128, 255 });

    return .{ arg0, arg1 };
}

pub fn classify(args: Args) usize {
    const arg0 = args[0].?;
    const arg1 = args[1].?;
    if (arg0.unk0.raw == psx.addr(arg1)) return 1;
    if (arg0.unk4.raw == psx.addr(arg1) + 0xD1C) return 2;
    return 0;
}
