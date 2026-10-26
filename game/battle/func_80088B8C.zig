//! Camera-mode tick: counts the target's risk every 30 game ticks while the battle camera is in mode 1 to 3
//! (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");

/// orig: func_80088B8C (src/BATTLE/BATTLE.PRG/146C.c)
/// Every 30 ticks, raises the character's risk while the targeted actor is marked (status 8).
pub fn func_80088B8C() callconv(.c) void {
    if (v.g.D_800F196C().* == 2 and v.g._cameraMode().* < 4 and v.g._cameraMode().* != 0) {
        if (v.g.D_800E8498().* == 0 and
            (psx.get(v.g.vs_battle_actors()[@as(usize, v.g.D_800F19CC().*.?.unk8.unk4.unk0.targetActor)].?.stats).?.statuses & 8) != 0 and
            v.g.D_800F19CC().*.?.unk8.unk4.unk40 == 0)
        {
            if (v.g.D_800F19CC().*.?.unk8.unk4.unk0.targetActor == 0) {
                const stats = psx.get(v.g.vs_battle_characterState().*.?.stats).?;
                if (stats.risk < 100) {
                    stats.risk +%= 1;
                }
            }
        }
        v.g.D_800E8498().* = @rem(v.g.D_800E8498().* +% v.g.vs_gametime_tickspeed().*, 30);
    }
}
