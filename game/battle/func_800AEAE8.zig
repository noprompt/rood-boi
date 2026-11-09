//! Scales the scratchpad actor transform offset by the actor's size and rotation (pc/src/game/BATTLE/BATTLE.PRG/44F14.c).
const psx = @import("common").psx;
const v = @import("views_44F14");
const c = @import("c_44F14");

/// orig: func_800AEAE8 (pc/src/game/BATTLE/BATTLE.PRG/44F14.c)
/// Sets the scale defaults, derives the scratchpad offset from the actor's extents and scale, and copies its rotation.
pub fn func_800AEAE8(actor: ?*v.D_800F4538_t) callconv(.c) void {
    const a = actor.?;
    const scratch: *v.actorTransformScratch = @ptrFromInt(0x1F80035C);

    v.g.D_800F2458().scales[0] = 64;
    v.g.D_800F2458().scales[1] = 64;
    v.g.D_800F2458().scales[2] = 64;

    // 0x10001000 as one int covers unk2C and unk2E, both 0x1000 (little endian).
    if (psx.fieldAt(c_int, &a.unk0.unk2C, 0).* == 0x10001000 and a.unk0.unk30 == 4096) {
        scratch.offset.vx = psx.conv(i16, @as(c_int, psx.conv(i16, psx.fieldAt(u16, &a.unk704.unk0, 328).*)) >> 1);
        scratch.offset.vy = psx.conv(i16, @as(c_int, psx.conv(i16, psx.fieldAt(u16, &a.unk704.unk0, 330).*)) >> 1);
        scratch.offset.vz = psx.conv(i16, @as(c_int, psx.conv(i16, psx.fieldAt(u16, &a.unk704.unk0, 332).*)) >> 1);
    } else {
        scratch.offset.vx = psx.conv(i16, @divTrunc(@as(c_int, psx.fieldAt(i16, &a.unk704.unk0, 328).*) *% @as(c_int, a.unk0.unk2C), 8192));
        scratch.offset.vy = psx.conv(i16, @divTrunc(@as(c_int, psx.fieldAt(i16, &a.unk704.unk0, 330).*) *% @as(c_int, a.unk0.unk2E), 8192));
        scratch.offset.vz = psx.conv(i16, @divTrunc(@as(c_int, psx.fieldAt(i16, &a.unk704.unk0, 332).*) *% @as(c_int, a.unk0.unk30), 8192));
    }

    scratch.offset.vx = psx.conv(i16, @divTrunc(@as(c_int, scratch.offset.vx) *% @as(c_int, a.unk183C), 4096));
    scratch.offset.vy = psx.conv(i16, @divTrunc(@as(c_int, scratch.offset.vy) *% @as(c_int, a.unk183C), 4096));
    scratch.offset.vz = psx.conv(i16, @divTrunc(@as(c_int, scratch.offset.vz) *% @as(c_int, a.unk183C), 4096));

    c.func_800B07DC(@ptrCast(a));

    scratch.angleX = a.unk0.unk14;
    scratch.angleY = a.unk0.unk16;
}
