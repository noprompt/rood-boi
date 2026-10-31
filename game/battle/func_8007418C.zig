//! Steps a scratch vector toward a target (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007418C (src/BATTLE/BATTLE.PRG/146C.c)
/// Copies the vector at D_800F1910's unk4 into a local and steps it toward a target with arguments 0 and 0x28.
pub fn func_8007418C() callconv(.c) c_int {
    // The C leaves the local's pad field uninitialised; only vx, vy and vz are copied.
    var sp10: v.SVECTOR = undefined;
    const src = &v.g.D_800F1910().unk4.unk0.unk4;
    sp10.vx = psx.conv(i16, psx.conv(u16, src.vx));
    sp10.vy = psx.conv(i16, psx.conv(u16, src.vy));
    sp10.vz = psx.conv(i16, psx.conv(u16, src.vz));
    return c._stepTowardTarget(psx.cptr(c.SVECTOR, &sp10), 0, 0x28);
}
