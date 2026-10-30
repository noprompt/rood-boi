//! zig_diff spec: vs_battle_getLimbStatus -> get_limb_status.getLimbStatus (5BF94.c).
//! Inputs: one limb in the arena with hp and maxHp chosen so that every ordered
//! comparison in the C is hit with its two sides equal (hp == 2, hp*4 == maxHp,
//! hp*4 == maxHp*3, hp == maxHp), plus random small hp and maxHp (negative values
//! included) and the i16 extremes. The C has no callees and no null test, so the
//! limb is always a valid object.
const std = @import("std");
const zd = @import("zdiff");
const v = @import("views_5BF94");
pub const Args = std.meta.ArgsTuple(@TypeOf(@import("port").getLimbStatus));

pub const classes = [_][:0]const u8{ "critical", "damaged", "wounded", "good", "excellent" };

pub fn prepare(ctx: *zd.Ctx) Args {
    const limb = ctx.alloc(v.vs_battle_uiEquipment_limb);
    var hp = ctx.range(i16, -8, 40);
    var maxHp = ctx.range(i16, -8, 60);
    switch (ctx.range(u8, 0, 11)) {
        0 => hp = 2,
        1 => maxHp = hp * 4,
        2 => {
            const x = ctx.range(i16, -3, 13);
            hp = 3 * x;
            maxHp = 4 * x;
        },
        3 => maxHp = hp,
        4 => {
            hp = ctx.pick(i16, &.{ -32768, -1, 32767 });
            maxHp = ctx.pick(i16, &.{ -32768, -1, 0, 32767 });
        },
        else => {},
    }
    limb.hp = hp;
    limb.maxHp = maxHp;
    return .{limb};
}

pub fn classify(args: Args) usize {
    const limb = args[0].?;
    const hp: c_int = limb.hp;
    const maxHp: c_int = limb.maxHp;
    if (hp < 2) return 0;
    if (hp * 4 < maxHp) return 1;
    if (hp * 4 < maxHp * 3) return 2;
    if (hp < maxHp) return 3;
    return 4;
}
