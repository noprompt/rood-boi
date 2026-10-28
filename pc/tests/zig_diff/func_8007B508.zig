//! zig_diff spec: func_8007B508 -> func_8007B508.func_8007B508 (146C.c).
//! Inputs: the state flag (0, 1, 2 or 3, which the stub returns in every call; 0, 2 and 3
//! pass the first test, 1 does not), the art-or-ability unlock test (true or false), and
//! the D_800F19CC action block: action index 0-255 with its `unlocked` bit, unk40,
//! unk2C07 and targetActor, all zero or nonzero, plus D_800F1864 zero or any i32.
//! The first block always returns, so nothing a callee does is read back after it;
//! the stubs answer only the flag and the art test. The second block reads the
//! object and the action table, which prepare fills.
const std = @import("std");
const zd = @import("zdiff");
const psx = @import("common").psx;
const v = @import("views_146C");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").func_8007B508));

pub const classes = [_][:0]const u8{ "art-first-block", "art-flag-1", "second-block", "fallthrough" };

var flag_val: u8 = 0;
var art_unlocked: bool = false;

pub const stubs = struct {
    pub fn vs_battle_getStateFlag(ctx: *zd.Ctx, flag: anytype) u8 {
        _ = ctx;
        _ = flag;
        return flag_val;
    }

    pub fn _isArtOrAbilityUnlocked(ctx: *zd.Ctx) c_int {
        if (!art_unlocked) return 0;
        return 1 + @as(c_int, ctx.value(u4));
    }
};

pub fn prepare(ctx: *zd.Ctx) Args {
    flag_val = ctx.range(u8, 0, 3);
    art_unlocked = ctx.chance(2);

    v.g.D_800F1864().* = if (ctx.chance(2)) 0 else ctx.int(i32);

    const obj = ctx.alloc(v.D_800F19CC_t);
    const acts = v.g.actions();
    const idx = ctx.range(u16, 0, 255);
    obj.unk8.actionIndex = idx;
    psx.setBits(&acts[idx], "unlocked", if (ctx.chance(3)) 1 else 0);
    obj.unk2C07 = if (ctx.chance(2)) 0 else ctx.range(u8, 1, 255);
    obj.unk8.unk4.unk40 = if (ctx.chance(2)) 0 else ctx.edge(i32, &.{ -1, 1, 0x7fffffff, -2147483648 });
    obj.unk8.unk4.unk0.targetActor = if (ctx.chance(2)) 0 else ctx.edge(u8, &.{ 1, 128, 255 });

    // Often make the second block run to its end.
    if (ctx.chance(2)) {
        psx.setBits(&acts[idx], "unlocked", 0);
        obj.unk8.unk4.unk40 = 0;
        obj.unk2C07 = 0;
        obj.unk8.unk4.unk0.targetActor = 0;
    }

    v.g.D_800F19CC().* = obj;
    return .{};
}

pub fn classify(args: Args) usize {
    _ = args;
    if (art_unlocked) return if (flag_val == 1) 1 else 0;
    const obj = v.g.D_800F19CC().*.?;
    const acts = v.g.actions();
    const idx = obj.unk8.actionIndex;
    const second = idx != 0 and
        psx.getBits(&acts[idx], "unlocked") == 0 and
        obj.unk8.unk4.unk40 == 0 and
        obj.unk2C07 == 0 and
        obj.unk8.unk4.unk0.targetActor == 0;
    return if (second) 2 else 3;
}
