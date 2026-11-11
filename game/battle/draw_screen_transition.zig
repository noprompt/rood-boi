//! Screen transition drawing: the fade and wipe primitives and the transition's alpha and step
//! (pc/src/game/BATTLE/BATTLE.PRG/146C.c).
const std = @import("std");
const common = @import("common");
const psx = common.psx;
const gte = common.gte;
const v = @import("views_146C");
const c = @import("c_146C");
const sprite_item = common.sprite_item;

/// orig: _drawScreenTransition (pc/src/game/BATTLE/BATTLE.PRG/146C.c)
/// Draws the current screen transition effect into the ordering table, then advances its alpha and step.
pub fn drawScreenTransition(ot: ?*anyopaque) callconv(.c) void {
    if (alpha() != 0) {
        switch (v.g.vs_battle_screenTransitionEffect().*) {
            0, 4, 5 => fadeBlack(ot),
            1 => fadeWhite(ot),
            2 => wipe(ot),
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

/// `ot + 4` as the C computes it on a void pointer.
fn otPlus4(ot: ?*anyopaque) ?*anyopaque {
    const base: usize = if (ot) |q| @intFromPtr(q) else 0;
    return @ptrFromInt(base +% 4);
}

/// A corner as x low, y high.
fn xy(x: c_int, y: c_int) c_int {
    return (x & 0xFFFF) | (y << 16);
}

/// The alpha as a grey (setRGB0 with the current alpha, a byte).
fn grey() c_int {
    return @as(c_int, psx.conv(u8, alpha())) * 0x010101;
}

/// SetDrawMode(dr, 0, 1, tpage, an empty RECT): the draw mode (dither on, `tpage`) and the texture window cleared.
fn drawMode(ot: ?*anyopaque, tpage: c_int) void {
    sprite_item.drawModeWindow(otPlus4(ot), 0x200 | (tpage & 0x1FF), 0);
}

const screen = [4]c_int{ 0, 320, 240 << 16, 320 | (240 << 16) };

/// Fade to black: a semi-transparent full-screen quad.
fn fadeBlack(ot: ?*anyopaque) void {
    sprite_item.flat(otPlus4(ot), 4, true, grey(), &screen);
    drawMode(ot, 64);
}

/// Fade to white: a full-screen quad, opaque only at full alpha.
fn fadeWhite(ot: ?*anyopaque) void {
    sprite_item.flat(otPlus4(ot), 4, alpha() != 255, grey(), &screen);
    drawMode(ot, 32);
}

/// RotTrans of (x, y, 0) through the current matrices, the projected point as x low, y high.
fn rotTransAt(view: *const gte.View, pos: *v.SVECTOR, projected: *v.VECTOR, x: c_int, y: c_int) c_int {
    pos.vx = psx.conv(i16, x);
    pos.vy = psx.conv(i16, y);
    gte.transformTo(projected, view, pos);
    return xy(@as(c_int, psx.conv(i16, projected.vx)), @as(c_int, psx.conv(i16, projected.vy)));
}

/// Screen wipe: a rotated, translated frame of the covered and edge polygons and the edge's gradient.
fn wipe(ot: ?*anyopaque) void {
    var rotTransMatrix: v.MATRIX = std.mem.zeroes(v.MATRIX);
    var screenCenter: v.VECTOR = std.mem.zeroes(v.VECTOR);
    var zRotation: v.SVECTOR = std.mem.zeroes(v.SVECTOR);
    var wipeEdgePos: v.SVECTOR = std.mem.zeroes(v.SVECTOR);
    var projectedPos: v.VECTOR = std.mem.zeroes(v.VECTOR);

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
    const view = gte.viewOf(&rotTransMatrix, gte.no_screen);

    wipeEdgePos.vz = 0;
    const scaled = @divTrunc(alpha() *% 560, 255);
    const ex1 = @divTrunc(scaled -% 720, 2);
    const ex2 = scaled -% 360;
    const ex3 = scaled -% 200;

    // The covered quad runs from the left to ex1, the edge quad from ex1 to ex2, the gradient from ex2 to ex3.
    const a = rotTransAt(&view, &wipeEdgePos, &projectedPos, -360, -200);
    const b = rotTransAt(&view, &wipeEdgePos, &projectedPos, -360, 200);
    const cc = rotTransAt(&view, &wipeEdgePos, &projectedPos, ex1, -200);
    const d = rotTransAt(&view, &wipeEdgePos, &projectedPos, ex1, 200);
    const e = rotTransAt(&view, &wipeEdgePos, &projectedPos, ex2, -200);
    const f = rotTransAt(&view, &wipeEdgePos, &projectedPos, ex2, 200);
    const g = rotTransAt(&view, &wipeEdgePos, &projectedPos, ex3, -200);
    const h = rotTransAt(&view, &wipeEdgePos, &projectedPos, ex3, 200);

    const blue: c_int = 1 << 16;
    sprite_item.flat(otPlus4(ot), 4, false, blue, &[4]c_int{ a, cc, b, d });
    sprite_item.flat(otPlus4(ot), 4, false, blue, &[4]c_int{ cc, e, d, f });
    sprite_item.shaded(otPlus4(ot), 4, true, &[4]c_int{ 0xFFFFFF, 0, 0xFFFFFF, 0 }, &[4]c_int{ e, g, f, h });
    drawMode(ot, 64);
}
