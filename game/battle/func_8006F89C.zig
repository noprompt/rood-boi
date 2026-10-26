//! Opens the ability camera when an art or ability is unlocked or the current battle action is still locked; otherwise runs the plain tail (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8006F89C (src/BATTLE/BATTLE.PRG/146C.c)
/// Picks the ability camera or the plain tail for the battle state in D_800F18FC.
pub fn func_8006F89C() callconv(.c) void {
    switch (v.g.D_800F18FC().*) {
        0 => c.func_8006F5FC(),
        2 => {
            if (c._isArtOrAbilityUnlocked() != 0 or blk: {
                const d = v.g.D_800F19CC().*.?;
                break :blk d.unk8.actionIndex != 0 and
                    psx.getBits(psx.at(v.g.actions(), d.unk8.actionIndex), "unlocked") == 0 and
                    d.unk8.unk4.unk40 == 0 and
                    d.unk2C07 == 0 and
                    d.unk8.unk4.unk0.targetActor == 0;
            }) {
                v.g._cameraMode().* = 0xD;
                c.func_8009E070(0, null, 6);
                c.func_8006F848();
                c.func_8008D594(1);
            } else {
                c.func_8006F5FC();
            }
        },
        else => {
            if (blk: {
                const d = v.g.D_800F19CC().*.?;
                break :blk d.unk8.actionIndex != 0 and
                    psx.getBits(psx.at(v.g.actions(), d.unk8.actionIndex), "unlocked") == 0 and
                    d.unk8.unk4.unk40 == 0 and
                    d.unk2C07 == 0 and
                    d.unk8.unk4.unk0.targetActor == 0;
            }) {
                v.g._cameraMode().* = 0xD;
                c.func_8009E070(0, null, 6);
                c.func_8006F848();
                c.func_8008D594(1);
            } else {
                c.func_8006F5FC();
            }
        },
    }
}
