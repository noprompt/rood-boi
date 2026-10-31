//! Finishes a pending CD image load, or frees its staging buffer
//! (src/BATTLE/BATTLE.PRG/146C.c).
const std = @import("std");
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008F0FC (src/BATTLE/BATTLE.PRG/146C.c)
/// Uploads a finished TIM load and returns 0, or frees the staging buffer of a finished second load and returns 1; 0 otherwise.
pub fn func_8008F0FC() callconv(.c) c_int {
    if (v.g.D_800F1DAC().* != null and v.g.D_800F1DAC().*.?.state == 4) {
        var tim = std.mem.zeroes(v.TIM_IMAGE);

        v.g.D_800F1DD0().*.?[0] = 0x10;
        c.vs_battle_parseTim(v.g.D_800F1DD0().*.?, psx.cptr(c.TIM_IMAGE, &tim));
        if (tim.paddr) |paddr| {
            const prect = tim.prect.?;
            prect.x = psx.conv(i16, (@as(c_int, prect.x) & 0x3F) +%
                ((@as(c_int, v.g.D_800F1DC8().*) & 0xF) << 6));
            prect.y = psx.conv(i16, @as(c_int, psx.conv(u8, prect.y)) +%
                ((@as(c_int, v.g.D_800F1DC8().*) & 0x10) * 0x10));
            _ = c.LoadImage(psx.cptr(c.RECT, prect), paddr);
        }
        if (tim.caddr) |caddr| {
            c.vs_main_loadClut(@ptrCast(caddr), 0xE, 0, 0x100);
        }
        c.vs_main_freeCdQueueSlot(psx.cptr(c.vs_main_CdQueueSlot, v.g.D_800F1DAC().*.?));
        v.g.D_800F1DAC().* = null;
        return 0;
    }

    if (v.g.D_800F1DB0().* != null and v.g.D_800F1DB0().*.?.state == 4) {
        c.vs_main_freeHeapR(@ptrCast(v.g.D_800F1DD0().*));
        v.g.D_800F1DD0().* = null;
        c.vs_main_freeCdQueueSlot(psx.cptr(c.vs_main_CdQueueSlot, v.g.D_800F1DB0().*.?));
        v.g.D_800F1DB0().* = null;
        return 1;
    }
    return 0;
}
