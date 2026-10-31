//! Screen transition drawing: the fade and wipe primitives and the transition's alpha and step
//! (src/BATTLE/BATTLE.PRG/146C.c).
const std = @import("std");
const common = @import("common");
const psx = common.psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: _drawScreenTransition (src/BATTLE/BATTLE.PRG/146C.c)
/// Draws the current screen transition effect into the ordering table, then advances its alpha and step.
pub fn drawScreenTransition(ot: ?*anyopaque) callconv(.c) void {
    var rect: v.RECT = undefined;
    const memset = @extern(*const fn (?*anyopaque, c_int, usize) callconv(.c) ?*anyopaque, .{ .name = "memset" });
    _ = memset(&rect, 0, @sizeOf(v.RECT));

    if (alpha() != 0) {
        switch (v.g.vs_battle_screenTransitionEffect().*) {
            0, 4, 5 => fadeBlack(ot, &rect),
            1 => fadeWhite(ot, &rect),
            2 => wipe(ot, &rect),
            else => {},
        }
    }

    const step = v.g.vs_battle_screenTransitionStep();
    if (step.* == 1 or step.* == 2 or step.* == 5) {
        if (alpha() >= 255 -% v.g.vs_battle_screenTransitionSpeed().*) {
            if (step.* == 5) {
                step.* = 6;
            }
            v.g.vs_battle_screenTransitionAlpha().* = 255;
        } else {
            v.g.vs_battle_screenTransitionAlpha().* +%= v.g.vs_battle_screenTransitionSpeed().*;
        }
    } else if (step.* == 4 or step.* == 7) {
        if (alpha() <= v.g.vs_battle_screenTransitionSpeed().*) {
            v.g.vs_battle_screenTransitionAlpha().* = 0;
            step.* = 0;
        } else {
            v.g.vs_battle_screenTransitionAlpha().* -%= v.g.vs_battle_screenTransitionSpeed().*;
        }
    }
}

/// The current transition alpha.
fn alpha() c_int {
    return v.g.vs_battle_screenTransitionAlpha().*;
}

/// The frame buffer index, read each time the C reads it.
fn frameBuf() c_int {
    return v.g.vs_main_frameBuf().*;
}

/// The current frame's full-screen fill polygon.
fn polyF4() *v.POLY_F4 {
    return psx.at(v.g.vs_battle_screenTransitionPolyF4(), frameBuf());
}

/// The current frame's draw mode primitive.
fn drMode() *v.DR_MODE {
    return psx.at(v.g.vs_battle_screenTransitionDrMode(), frameBuf());
}

/// The current frame's edge gradient polygon.
fn edgeG4() *v.POLY_G4 {
    return psx.at(v.g.vs_battle_screenTransitionEdgePolyG4(), frameBuf());
}

/// The current frame's wipe polygon pair.
fn wipePoly() *v.vs_battle_screenTransitionWipePoly {
    return psx.at(v.g.vs_battle_screenTransitionWipePolyF4(), frameBuf());
}

/// `ot + 4` as the C computes it on a void pointer.
fn otPlus4(ot: ?*anyopaque) ?*anyopaque {
    const base: usize = if (ot) |q| @intFromPtr(q) else 0;
    return @ptrFromInt(base +% 4);
}

/// setRGB0 with the current alpha.
fn setRgb0(p: *v.POLY_F4) void {
    p.r0 = psx.conv(u8, alpha());
    p.g0 = psx.conv(u8, alpha());
    p.b0 = psx.conv(u8, alpha());
}

/// Fade to black: a semi-transparent full-screen quad.
fn fadeBlack(ot: ?*anyopaque, rect: *v.RECT) void {
    const p0 = polyF4();
    p0.x0 = 0;
    p0.y0 = 0;
    p0.x1 = 320;
    p0.y1 = 0;
    p0.x2 = 0;
    p0.y2 = 240;
    p0.x3 = 320;
    p0.y3 = 240;
    c.SetDrawMode(psx.cptr(c.DR_MODE, drMode()), 0, 1, 64, psx.cptr(c.RECT, rect));
    c.SetSemiTrans(polyF4(), 1);
    setRgb0(polyF4());
    c.AddPrim(otPlus4(ot), polyF4());
    c.AddPrim(otPlus4(ot), drMode());
}

/// Fade to white: a full-screen quad, opaque only at full alpha.
fn fadeWhite(ot: ?*anyopaque, rect: *v.RECT) void {
    const p0 = polyF4();
    p0.x0 = 0;
    p0.y0 = 0;
    p0.x1 = 320;
    p0.y1 = 0;
    p0.x2 = 0;
    p0.y2 = 240;
    p0.x3 = 320;
    p0.y3 = 240;
    c.SetDrawMode(psx.cptr(c.DR_MODE, drMode()), 0, 1, 32, psx.cptr(c.RECT, rect));

    if (alpha() == 255) {
        c.SetSemiTrans(polyF4(), 0);
    } else {
        c.SetSemiTrans(polyF4(), 1);
    }

    setRgb0(polyF4());
    c.AddPrim(otPlus4(ot), polyF4());
    c.AddPrim(otPlus4(ot), drMode());
}

const Xy = struct { x: i16, y: i16 };

/// RotTrans of (x, y, 0) through the current matrices, with the projected point stored as i16.
fn rotTransAt(pos: *v.SVECTOR, projected: *v.VECTOR, flag: *c_int, x: c_int, y: c_int) Xy {
    pos.vx = psx.conv(i16, x);
    pos.vy = psx.conv(i16, y);
    c.RotTrans(psx.cptr(c.SVECTOR, pos), psx.cptr(c.VECTOR, projected), flag);
    return .{ .x = psx.conv(i16, projected.vx), .y = psx.conv(i16, projected.vy) };
}

/// Screen wipe: a rotated, translated frame of the covered and edge polygons.
fn wipe(ot: ?*anyopaque, rect: *v.RECT) void {
    var rotTransMatrix: v.MATRIX = std.mem.zeroes(v.MATRIX);
    var screenCenter: v.VECTOR = std.mem.zeroes(v.VECTOR);
    var zRotation: v.SVECTOR = std.mem.zeroes(v.SVECTOR);
    var wipeEdgePos: v.SVECTOR = std.mem.zeroes(v.SVECTOR);
    var projectedPos: v.VECTOR = std.mem.zeroes(v.VECTOR);
    var flag: c_int = 0;

    const step = v.g.vs_battle_screenTransitionStep().*;
    const angle = v.g.vs_battle_screenTransitionWipeAngle().*;
    zRotation.vx = 0;
    zRotation.vy = 0;
    zRotation.vz = psx.conv(i16, if (step == 4 or step == 7) angle +% 2048 else angle);

    screenCenter.vx = 160;
    screenCenter.vy = 120;
    screenCenter.vz = 0;
    _ = c.RotMatrix_gte(psx.cptr(c.SVECTOR, &zRotation), psx.cptr(c.MATRIX, &rotTransMatrix));
    _ = c.TransMatrix(psx.cptr(c.MATRIX, &rotTransMatrix), psx.cptr(c.VECTOR, &screenCenter));
    c.SetRotMatrix(psx.cptr(c.MATRIX, &rotTransMatrix));
    c.SetTransMatrix(psx.cptr(c.MATRIX, &rotTransMatrix));

    wipeEdgePos.vz = 0;
    const scaled = @divTrunc(alpha() *% 560, 255);
    const ex1 = @divTrunc(scaled -% 720, 2);
    const ex2 = scaled -% 360;
    const ex3 = scaled -% 200;

    var p = rotTransAt(&wipeEdgePos, &projectedPos, &flag, -360, -200);
    wipePoly().covered.x0 = p.x;
    wipePoly().covered.y0 = p.y;

    p = rotTransAt(&wipeEdgePos, &projectedPos, &flag, -360, 200);
    wipePoly().covered.x2 = p.x;
    wipePoly().covered.y2 = p.y;

    p = rotTransAt(&wipeEdgePos, &projectedPos, &flag, ex1, -200);
    wipePoly().covered.x1 = p.x;
    wipePoly().covered.y1 = p.y;
    wipePoly().edge.x0 = p.x;
    wipePoly().edge.y0 = p.y;

    p = rotTransAt(&wipeEdgePos, &projectedPos, &flag, ex1, 200);
    wipePoly().covered.x3 = p.x;
    wipePoly().covered.y3 = p.y;
    wipePoly().edge.x2 = p.x;
    wipePoly().edge.y2 = p.y;

    p = rotTransAt(&wipeEdgePos, &projectedPos, &flag, ex2, -200);
    wipePoly().edge.x1 = p.x;
    wipePoly().edge.y1 = p.y;
    edgeG4().x0 = p.x;
    edgeG4().y0 = p.y;

    p = rotTransAt(&wipeEdgePos, &projectedPos, &flag, ex2, 200);
    wipePoly().edge.x3 = p.x;
    wipePoly().edge.y3 = p.y;
    edgeG4().x2 = p.x;
    edgeG4().y2 = p.y;

    p = rotTransAt(&wipeEdgePos, &projectedPos, &flag, ex3, -200);
    edgeG4().x1 = p.x;
    edgeG4().y1 = p.y;

    p = rotTransAt(&wipeEdgePos, &projectedPos, &flag, ex3, 200);
    edgeG4().x3 = p.x;
    edgeG4().y3 = p.y;

    c.AddPrim(otPlus4(ot), &wipePoly().covered);
    c.AddPrim(otPlus4(ot), &wipePoly().edge);
    c.AddPrim(otPlus4(ot), edgeG4());
    c.SetDrawMode(psx.cptr(c.DR_MODE, drMode()), 0, 1, 64, psx.cptr(c.RECT, rect));
    c.AddPrim(otPlus4(ot), drMode());
}
