//! The battle camera's scene draw: the background tile layout, the full-screen
//! flash quad, and the view matrices (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

const AnchorPackets = *const fn (?*anyopaque, ?*anyopaque, c_int) callconv(.c) void;

/// orig: func_8008EC48 (src/BATTLE/BATTLE.PRG/146C.c)
/// Draws the scene: the background layout when one is loaded, else the flash quad when set, else the camera's view matrices.
pub fn func_8008EC48(arg0: ?*v.VECTOR) callconv(.c) void {
    const scratch: *v.vs_scratch_t = @ptrFromInt(0x1F800000);

    if (v.g.D_800F1DC9().* != 0 and v.g.D_800F1DCC().* != null) {
        const layout = v.g.D_800F1DCC().*.?;
        if (psx.conv(c_uint, layout.width -% 1) < 31 and psx.conv(c_uint, layout.height -% 1) < 31) {
            const x: c_int = @divTrunc(scratch.camera.angles.vy *% @as(c_int, v.g.D_800F1DB8().*), 4096) -% @as(c_int, v.g.D_800F1DB4().*);
            const y: c_int = @as(c_int, v.g.D_800F1DB6().*) -% @divTrunc(scratch.camera.angles.vx *% @as(c_int, v.g.D_800F1DBA().*), 4096);

            // ROOD_PC: PC_ANCHOR_PACKETS(PC_ANCHOR_SCENE, ...) around the tile draw (pc/src/widescreen.h).
            const PC_ANCHOR_SCENE: c_int = 0x14;
            const anchor_start: ?*anyopaque = @ptrFromInt(@as(usize, psx.rawOf(scratch.unk0)));
            c.func_8009147C(psx.cptr(c.vs_battle_backgroundLayout, layout), x, y, @as(c_int, v.g.D_800F1DC8().*));
            if (psx.weak(AnchorPackets, "pc_hw_anchor_packets")) |hook| {
                hook(anchor_start, @ptrFromInt(@as(usize, psx.rawOf(scratch.unk0))), PC_ANCHOR_SCENE);
            }
        }
    } else if (v.g.D_800F1DC6().* != 0) {
        const raw: *align(4) anyopaque = @alignCast(psx.get(scratch.unk0).?);
        var prim: *v.POLY_FT4 = @ptrCast(raw);

        const tag: *v.P_TAG = @ptrCast(prim);
        psx.setBits(tag, "len", 9);
        tag.code = 0x2c;

        prim.x0 = 0;
        prim.y0 = 0;
        prim.x1 = 320;
        prim.y1 = 0;
        prim.x2 = 0;
        prim.y2 = 240;
        prim.x3 = 320;
        prim.y3 = 240;

        prim.u0 = 248;
        prim.v0 = 248;
        prim.u1 = 249;
        prim.v1 = 248;
        prim.u2 = 248;
        prim.v2 = 249;
        prim.u3 = 249;
        prim.v3 = 249;

        const b = v.g.D_800F1BB0();
        if (b.unk6 != 0) {
            var red: c_int = 128 +% (@as(c_int, b.unk0) *% 4);
            var green: c_int = 128 +% (@as(c_int, b.unk1) *% 4);
            var blue: c_int = 128 +% (@as(c_int, b.unk2) *% 4);
            red = @as(c_int, psx.conv(i16, c.vs_battle_clamp(psx.conv(i16, red), 0, 255)));
            green = @as(c_int, psx.conv(i16, c.vs_battle_clamp(psx.conv(i16, green), 0, 255)));
            blue = @as(c_int, psx.conv(i16, c.vs_battle_clamp(psx.conv(i16, blue), 0, 255)));
            prim.r0 = psx.conv(u8, red);
            prim.g0 = psx.conv(u8, green);
            prim.b0 = psx.conv(u8, blue);
        } else {
            prim.r0 = 128;
            prim.g0 = 128;
            prim.b0 = 128;
        }
        prim.tpage = 0x11;
        prim.clut = 0x38B1;

        const ot: ?*anyopaque = @ptrFromInt(@as(usize, psx.rawOf(scratch.unk4) +% 0x1FFC));
        const cur = prim;
        prim = @ptrFromInt(@intFromPtr(prim) +% @sizeOf(v.POLY_FT4));
        c.AddPrim(ot, cur);
        psx.put(&scratch.unk0, prim);
    } else {
        var angles: *v.VECTOR = undefined;
        if (arg0) |given| {
            angles = given;
        } else if (psx.get(v.g.vs_battle_roomData().sectionB)) |room| {
            angles = @ptrCast(&room.unk14);
        } else {
            angles = @ptrCast(v.g.D_800F1CE0());
        }

        var position: v.VECTOR = undefined;
        position.vx = @divTrunc(scratch.camera.position.vx, 4096);
        position.vy = @divTrunc(scratch.camera.position.vy, 4096);
        position.vz = @divTrunc(scratch.camera.position.vz, 4096);
        position.vx *%= scratch.camera.farClip;
        position.vy *%= scratch.camera.farClip;
        position.vz *%= scratch.camera.farClip;
        position.vx = @divTrunc(position.vx, 4096);
        position.vy = @divTrunc(position.vy, 4096);
        position.vz = @divTrunc(position.vz, 4096);

        c.SetRotMatrix(psx.cptr(c.MATRIX, &scratch.viewMatrix));
        c.SetTransMatrix(psx.cptr(c.MATRIX, &scratch.viewMatrix));

        var matrix: v.MATRIX = undefined;
        if (scratch.camera.farClip != 4096) {
            c.func_80098648(psx.cptr(c.VECTOR, &position), psx.cptr(c.VECTOR, angles), psx.cptr(c.MATRIX, &matrix));
        } else {
            c.func_800985AC(psx.cptr(c.VECTOR, &position), psx.cptr(c.VECTOR, angles), psx.cptr(c.MATRIX, &matrix));
        }
        c.SetRotMatrix(psx.cptr(c.MATRIX, &matrix));
        c.SetTransMatrix(psx.cptr(c.MATRIX, &matrix));
        c.func_8009820C(@ptrCast(v.g.D_80068C1C()));
    }
}
