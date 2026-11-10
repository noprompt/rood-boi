//! Copies the scratchpad word at offset 0x3F8 into D_800F58C4 (pc/src/game/BATTLE/BATTLE.PRG/6FC00.c).
const v = @import("views_6FC00");
const pad = @import("common").pad;

/// orig: func_800D9538 (pc/src/game/BATTLE/BATTLE.PRG/6FC00.c)
/// Copies the scratchpad word at offset 0x3F8 into D_800F58C4.
pub fn func_800D9538() callconv(.c) void {
    const scratch: *const i32 = @ptrFromInt(pad.addr(0x3F8));
    v.g.D_800F58C4().* = scratch.*;
}
