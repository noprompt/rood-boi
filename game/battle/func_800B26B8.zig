//! Copies a saved bone matrix into the bone table and an actor, transformed by a parent matrix (pc/src/game/BATTLE/BATTLE.PRG/49268.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_49268");
const c = @import("c_49268");

/// orig: func_800B26B8 (pc/src/game/BATTLE/BATTLE.PRG/49268.c)
/// Takes the saved bone matrix, rotates and translates it by the parent matrix, and stores it into the bone table and the actor.
pub fn func_800B26B8(actor_in: ?*v.D_800F4538_t, parent: ?*v.MATRIX, bone: c_int, saved: c_int) callconv(.c) void {
    const scratch: *v.boneTransformScratch = @ptrFromInt(0x1F80035C);
    const matrix: *v.MATRIX = @ptrFromInt(0x1F8003C0);

    const actor = actor_in.?;
    // The saved bone matrices are the 32-byte records from unk1890.
    const saved_matrix = psx.fieldAt(v.MATRIX, &actor.unk1890, @as(isize, saved -% 1) << 5);
    matrix.* = saved_matrix.*;

    c.func_800B196C(psx.cptr(c.MATRIX, parent.?), psx.cptr(c.MATRIX, matrix));

    // gte_SetRotMatrix(parent); gte_SetTransMatrix(parent);
    const words: *align(1) const [8]c_uint = @ptrCast(parent.?);
    c.CTC2(words[0], 0);
    c.CTC2(words[1], 1);
    c.CTC2(words[2], 2);
    c.CTC2(words[3], 3);
    c.CTC2(words[4], 4);
    c.CTC2(words[5], 5);
    c.CTC2(words[6], 6);
    c.CTC2(words[7], 7);

    scratch.translation.vx = psx.conv(i16, psx.fieldAt(u16, &saved_matrix.t[0], 0).*);
    scratch.translation.vy = psx.conv(i16, psx.fieldAt(u16, &saved_matrix.t[1], 0).*);
    scratch.translation.vz = psx.conv(i16, psx.fieldAt(u16, &saved_matrix.t[2], 0).*);

    // gte_ldv0(0x1F8003A8); gte_rtv0tr2(); gte_stlvnl(0x1F8003D4);
    const tr: [*]align(1) const c_uint = @ptrFromInt(0x1F8003A8);
    c.MTC2(tr[0], 0);
    c.MTC2(tr[1], 1);
    _ = c.doCOP2(0x0480012);
    const out: [*]align(1) c_uint = @ptrFromInt(0x1F8003D4);
    out[0] = c.MFC2(25);
    out[1] = c.MFC2(26);
    out[2] = c.MFC2(27);

    // *psx_to_ptr(MATRIX*, boneOffset + psx_to_int(int, table)) = *matrix;
    const bone_offset: c_int = bone << 5;
    const table = v.g.D_800F3C58();
    const table_addr: c_uint = psx.conv(c_uint, bone_offset) +% psx.addr(table);
    @as(*align(1) v.MATRIX, @ptrFromInt(@as(usize, table_addr))).* = matrix.*;

    // actor->bones[bone] = *matrix;
    psx.fieldAt(v.MATRIX, &actor.bones, bone_offset).* = matrix.*;
}
