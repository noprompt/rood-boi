//! zig_diff spec: func_8006F89C -> func_8006F89C.func_8006F89C (146C.c).
//! Inputs: the switch selector D_800F18FC (0, 2, and others including 0x10002
//! and INT_MIN, so a narrowed selector differs), a battle object D_800F19CC_t
//! in the arena with action index 0 or 1..255 (vs_main_actions has 256
//! entries; the C indexes it with a u16, so larger indices are not built), the
//! action's unlocked bit, and the zero/nonzero tests of unk40 (with and without
//! the sign bit), unk2C07 and targetActor. _isArtOrAbilityUnlocked's stub returns
//! a value chosen by prepare: 0 when the art is locked, otherwise an odd nonzero
//! value. The three callees are void recorders: the C reads no global or field
//! back after them, so nothing they could change is observable to it.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8006F89C));

pub const classes = [_][:0]const u8{ "case-0", "case-2-art", "case-2-chain", "case-2-plain", "default-chain", "default-plain" };

var art_unlocked: bool = false;

pub const stubs = struct {
    pub fn _isArtOrAbilityUnlocked(ctx: *zd.Ctx) c_int {
        if (!art_unlocked) return 0;
        return ctx.value(c_int) | 1;
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    const obj = ctx.alloc(v.D_800F19CC_t);
    v.g.D_800F19CC().* = obj;
    v.g.D_800F18FC().* = ctx.edge(i32, &.{ 0, 2, 2, 1, 3, -1, 0x10002, -2147483648 });
    art_unlocked = ctx.chance(3);

    const index: u16 = if (ctx.chance(5))
        0
    else if (ctx.chance(2))
        ctx.edge(u16, &.{ 1, 2, 127, 128, 255 })
    else
        ctx.range(u16, 1, 255);
    obj.unk8.actionIndex = index;
    if (index != 0) {
        psx.setBits(&v.g.actions()[index], "unlocked", if (ctx.chance(3)) 1 else 0);
    }

    obj.unk2C07 = if (ctx.chance(4)) ctx.edge(u8, &.{ 1, 0x80, 0xFF }) else 0;
    obj.unk8.unk4.unk0.targetActor = if (ctx.chance(4)) ctx.edge(u8, &.{ 1, 0x80, 0xFF }) else 0;
    obj.unk8.unk4.unk40 = if (ctx.chance(4)) ctx.edge(i32, &.{ -1, 1, 0x7fffffff, -2147483648 }) else 0;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    const sel = v.g.D_800F18FC().*;
    if (sel == 0) return 0;
    const obj = v.g.D_800F19CC().*.?;
    const idx = obj.unk8.actionIndex;
    const chain = idx != 0 and
        psx.getBits(&v.g.actions()[idx], "unlocked") == 0 and
        obj.unk8.unk4.unk40 == 0 and
        obj.unk2C07 == 0 and
        obj.unk8.unk4.unk0.targetActor == 0;
    if (sel == 2) {
        if (art_unlocked) return 1;
        return if (chain) 2 else 3;
    }
    return if (chain) 4 else 5;
}
