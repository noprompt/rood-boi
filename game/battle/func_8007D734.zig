//! The five-panel screen wipe of the battle transition (src/BATTLE/BATTLE.PRG/146C.c).
const std = @import("std");
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007D734 (src/BATTLE/BATTLE.PRG/146C.c)
/// Draws the five wipe panels into the ordering table `ot` and steps the wipe state machine.
pub fn func_8007D734(ot: ?*anyopaque) callconv(.c) void {
    var sp18: v.MATRIX = undefined;
    // translation.vz and the pad words are uninitialised in the original; zeroed here.
    var translation = std.mem.zeroes(v.VECTOR);
    // vertex.pad is never read by the GTE; zeroed like translation.
    var vertex = std.mem.zeroes(v.SVECTOR);
    var sp50: v.VECTOR = undefined;
    var sp60 = std.mem.zeroes(v.RECT);
    var sp68: c_int = undefined;

    _ = c.memset(&sp60, @as(c_int, 0), @as(usize, 8));

    if (v.g.D_800F1B98().* == 2) {
        translation.vx = v.g.D_800F1A68().unk0 +% 0xA0;
        translation.vy = v.g.D_800F1A68().unk4 +% 0x70;
        _ = c.RotMatrix_gte(@ptrCast(v.g.D_800F1A28()), psx.cptr(c.MATRIX, &sp18));
        _ = c.TransMatrix(psx.cptr(c.MATRIX, &sp18), psx.cptr(c.VECTOR, &translation));
        _ = c.ScaleMatrix(psx.cptr(c.MATRIX, &sp18), @ptrCast(v.g.D_800F1A30()));
        c.SetRotMatrix(psx.cptr(c.MATRIX, &sp18));
        c.SetTransMatrix(psx.cptr(c.MATRIX, &sp18));

        const m30 = v.g.D_800F1A30();
        if ((@as(c_int, v.g.D_800F1A28()[2]) & 0xFFF) != 0 or m30[0] != 0x1000 or m30[1] != m30[0]) {
            // Rotated or scaled: five quads.
            const buf = v.g.D_800F1ABC().*.?;
            var s1: c_int = 0;
            while (true) {
                const idx: c_int = v.g.vs_main_frameBuf().* *% 5 +% s1;
                const poly = psx.at(&buf.poly, idx);
                const code = v.g.D_800F1A78();
                poly.r0 = code.r0;
                poly.g0 = code.g0;
                poly.b0 = code.b0;
                if ((psx.conv(u16, v.g.D_800F1A2C().*) & 0xFFF) == 0 and v.g.D_800F1A40().* != 0) {
                    poly.tpage = c.GetTPage(2, v.g.D_800F1B9C().*, s1 *% 64 +% ((v.g.vs_main_frameBuf().* ^ 1) *% 320), 0);
                } else {
                    poly.tpage = c.GetTPage(2, v.g.D_800F1B9C().*, s1 *% 64 +% ((v.g.vs_main_frameBuf().* & 1) *% 320), 0);
                }

                vertex.vx = psx.conv(i16, s1 *% 64 -% 160);
                vertex.vy = -0x70;
                vertex.vz = 0;
                c.RotTrans(psx.cptr(c.SVECTOR, &vertex), psx.cptr(c.VECTOR, &sp50), &sp68);
                poly.x0 = psx.conv(i16, sp50.vx);
                poly.y0 = psx.conv(i16, sp50.vy);

                vertex.vx = psx.conv(i16, s1 *% 64 -% 96);
                vertex.vy = -0x70;
                vertex.vz = 0;
                c.RotTrans(psx.cptr(c.SVECTOR, &vertex), psx.cptr(c.VECTOR, &sp50), &sp68);
                poly.x1 = psx.conv(i16, sp50.vx);
                poly.y1 = psx.conv(i16, sp50.vy);

                vertex.vx = psx.conv(i16, s1 *% 64 -% 160);
                vertex.vy = 0x6F;
                vertex.vz = 0;
                c.RotTrans(psx.cptr(c.SVECTOR, &vertex), psx.cptr(c.VECTOR, &sp50), &sp68);
                poly.x2 = psx.conv(i16, sp50.vx);
                poly.y2 = psx.conv(i16, sp50.vy);

                vertex.vx = psx.conv(i16, s1 *% 64 -% 96);
                vertex.vy = 0x6F;
                vertex.vz = 0;
                c.RotTrans(psx.cptr(c.SVECTOR, &vertex), psx.cptr(c.VECTOR, &sp50), &sp68);
                poly.x3 = psx.conv(i16, sp50.vx);
                poly.y3 = psx.conv(i16, sp50.vy);

                c.AddPrim(@as(?*anyopaque, @ptrFromInt(@intFromPtr(ot) +% @as(usize, v.g.D_800F1A44().* *% 4))), poly);
                s1 +%= 1;
                if (s1 >= 5) break;
            }
        } else {
            // Unrotated and unscaled: five sprites, each with its draw mode.
            const buf = v.g.D_800F1ABC().*.?;
            var s1: c_int = 0;
            while (true) {
                const idx: c_int = v.g.vs_main_frameBuf().* *% 5 +% s1;
                const code = v.g.D_800F1A78();
                const sprite = psx.at(&buf.sprite, idx);
                sprite.r0 = code.r0;
                sprite.g0 = code.g0;
                sprite.b0 = code.b0;
                const temp_s0: c_int = s1 << 6;
                sprite.x0 = psx.conv(i16, @as(c_int, psx.conv(u16, v.g.D_800F1A68().unk0)) +% temp_s0);
                sprite.y0 = psx.conv(i16, v.g.D_800F1A68().unk4);
                c.AddPrim(@as(?*anyopaque, @ptrFromInt(@intFromPtr(ot) +% @as(usize, v.g.D_800F1A44().* *% 4))), sprite);

                const page: u16 = if (v.g.D_800F1A40().* != 0)
                    c.GetTPage(2, v.g.D_800F1B9C().*, temp_s0 +% ((v.g.vs_main_frameBuf().* ^ 1) *% 0x140), 0)
                else
                    c.GetTPage(2, v.g.D_800F1B9C().*, temp_s0 +% ((v.g.vs_main_frameBuf().* & 1) *% 0x140), 0);

                // The DR_MODE slot follows the sprite array at byte 0x258; 12-byte entries, so 4-aligned.
                const dr: *v.DR_MODE = @alignCast(psx.byteAt(v.DR_MODE, buf, @as(isize, idx *% 12 +% 0x258)));
                c.SetDrawMode(psx.cptr(c.DR_MODE, dr), 0, 1, @as(c_int, page), psx.cptr(c.RECT, &sp60));
                c.AddPrim(@as(?*anyopaque, @ptrFromInt(@intFromPtr(ot) +% @as(usize, v.g.D_800F1A44().* *% 4))), dr);
                s1 +%= 1;
                if (s1 >= 5) break;
            }
        }
    }

    if (v.g.D_800F1B98().* == 1) {
        v.g.D_800F1B98().* = 2;
        return;
    }
    if (v.g.D_800F1B98().* >= 3) {
        v.g.D_800F1B98().* +%= 1;
        if (v.g.D_800F1B98().* >= 5) {
            v.g.D_800F1B98().* = 0;
            if (v.g.D_800F1ABC().*) |buf| {
                c.vs_main_freeHeapR(buf);
                v.g.D_800F1ABC().* = null;
            }
        }
    }
}
