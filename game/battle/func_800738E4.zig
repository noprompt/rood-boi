//! The battle-state reset that runs when a battle ends (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_800738E4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Clears the battle's view, actor and sound state; leaves through func_80073870 when the battle is ending.
pub fn func_800738E4() callconv(.c) void {
    c.func_8008D594(0);
    c.func_80095B70(0);
    v.g._firstPersonViewEnabled().* = 0;

    var i: c_int = 0;
    while (i < 16) : (i +%= 1) {
        const slot = v.g.vs_battle_actors()[@intCast(i)];
        if (slot) |actor| {
            if (actor.unk8 == 0x10) {
                actor.unk8 = 0x40;
            }
        }
    }

    _ = c.func_800DEC88(null);
    c.func_800DC638();
    if (c.func_800BEC58(0xA, 0, 0, 0) == 1 or
        (v.g.D_80050468().unk0 != 0 and c.func_800BEC58(0x10, 0, 0, 0) == 1))
    {
        c.func_80073870();
        return;
    }

    // uninitialised in the original: the rest of the struct is not written before the call
    var sp10: v.D_800F4538_unk64 = .{ .unk0 = 0, .unk1 = 0, .unk2 = 0, .unk3 = 0 };
    sp10.unk0 = 0;
    _ = c.func_8009F990(-1, psx.cptr(c.D_800F4538_unk64, &sp10));

    var j: c_int = 0;
    while (j < 16) : (j +%= 1) {
        _ = c.func_8009D7E8(j, 0);
        _ = c.func_800A07FC(j, 0);
    }

    c.func_80093A14();
    c.vs_battle_setFarClip(0x1000, 1);
    c.vs_battle_setCameraRoll(0);
    _ = c.func_8007BD8C(0);

    const sound = v.g.vs_main_soundData();
    if (sound.unk4 == 0xFFFF) {
        if (v.g.D_800F18AC().* != 0) {
            _ = c.func_80045000(v.g.D_800F18AC().*, 0x7F, 0);
        }
    } else if (v.g.D_800F18AC().* != 0 and
        sound.unk4 == psx.at(&sound.unk14, v.g.D_800F18AC().* -% 1).*)
    {
        _ = c.func_8004552C(v.g.D_800F18AC().*, 0x7F, 0x3C);
    }
    c.func_8006F5CC();
}
