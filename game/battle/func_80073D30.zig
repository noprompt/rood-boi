//! Points the battle's pending effect request at a target actor and queues the effect (src/BATTLE/BATTLE.PRG/146C.c).
const std = @import("std");
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80073D30 (src/BATTLE/BATTLE.PRG/146C.c)
/// Fills the battle request for the target actor's limb and queues effect `arg0.unk6 + 6` from `arg1`'s position.
pub fn func_80073D30(arg0: ?*v._mpdRoomSectionA, arg1: ?*v.func_8006EBF8_t, targetActor: c_int) callconv(.c) void {
    var sp10: v.func_800CF0E8_t = std.mem.zeroes(v.func_800CF0E8_t);

    v.g.D_800F19CC().*.?.unk8.unk4.unk40 = 3;
    v.g.D_800F19CC().*.?.unk8.unk4A = 1;
    v.g.D_800F19CC().*.?.unk8.unk4C[0].unk40 = 0;
    v.g.D_800F19CC().*.?.unk8.unk4C[0].unk0.targetActor = psx.conv(u8, targetActor);
    const actor = psx.get(psx.at(v.g.vs_battle_actors(), targetActor).*.?.stats).?;
    v.g.D_800F19CC().*.?.unk8.unk4C[0].unk0.targetLimb = psx.conv(i8, psx.getBits(actor, "unk36"));
    v.g.D_800F19CC().*.?.unk4 = 1;
    v.g.D_800F19CC().*.?.unk0 = 0;
    v.g.D_800F19CC().*.?.unk29A8.vx = arg1.?.unk0.unk4.vx;
    v.g.D_800F19CC().*.?.unk29A8.vy = arg1.?.unk0.unk4.vy;
    v.g.D_800F19CC().*.?.unk29A8.vz = arg1.?.unk0.unk4.vz;
    c.func_80085B10(
        @as(c_int, arg0.?.unk0.unk6) +% 6,
        @ptrCast(&v.g.D_800F19CC().*.?.unk854[0]),
        @ptrCast(&v.g.D_800F19CC().*.?.unk8),
        1,
    );
    sp10.effectId = psx.conv(u16, @as(c_int, arg0.?.unk0.unk6) +% 6);
    sp10.unk4 = 5;
    sp10.unk10 = 4;
    sp10.unk2 = 1;
    sp10.unk3 = 0;
    sp10.unk14.u8[0] = psx.conv(u8, targetActor);
    sp10.unk16.u8[0] = 0xFD;
    _ = c.func_800CF3F8(psx.cptr(c.func_800CF0E8_t, &sp10), 0);
}
