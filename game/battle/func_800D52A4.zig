//! Effect motion integration over a linked list of effect nodes (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D52A4 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Steps every effect node in the list one tick: drag and gravity, then attraction toward its target.
pub fn func_800D52A4(node: ?*v.func_800D2904_t) callconv(.c) void {
    const drag: c_int = v.g.D_800F5618().*;
    const gravityX: c_int = v.g.D_800F5620().unk0;
    const gravityY: c_int = v.g.D_800F5620().unk4;
    const gravityZ: c_int = v.g.D_800F5620().unk8;

    var cur = node;
    while (cur) |n| {
        // state = (effectMotionState*)&node->unk8
        const state = psx.byteAt(v.effectMotionState, n, 8);
        var damping: c_int = @as(c_int, n.unk8) -% drag;

        state.vx = @divTrunc(state.vx *% damping +% (state.fx << 12), @as(c_int, n.unk8)) +%
            ((gravityX *% @as(c_int, state.gravityScale)) >> 12);
        state.x +%= state.vx;

        state.vy = @divTrunc(state.vy *% damping +% (state.fy << 12), @as(c_int, n.unk8)) +%
            ((gravityY *% @as(c_int, state.gravityScale)) >> 12);
        state.y +%= state.vy;

        state.vz = @divTrunc(state.vz *% damping +% (state.fz << 12), @as(c_int, n.unk8)) +%
            ((gravityZ *% @as(c_int, state.gravityScale)) >> 12);
        state.z +%= state.vz;

        const attr = psx.byteAt(v.effectAttractionView, n, 0);
        damping = attr.attraction;
        if (damping != 0) {
            var direction: v.VECTOR = undefined;
            direction.vx = @as(c_int, attr.targetX) -% (state.x >> 12);
            direction.vy = @as(c_int, attr.targetY) -% (state.y >> 12);
            direction.vz = @as(c_int, attr.targetZ) -% (state.z >> 12);
            if (direction.vx != 0 or direction.vy != 0 or direction.vz != 0) {
                _ = c.VectorNormal(psx.cptr(c.VECTOR, &direction), psx.cptr(c.VECTOR, &direction));
                direction.vx = (direction.vx *% damping) >> 12;
                direction.vy = (direction.vy *% damping) >> 12;
                direction.vz = (direction.vz *% damping) >> 12;
            }
            state.fx +%= state.ax +% direction.vx;
            state.fy +%= state.ay +% direction.vy;
            state.fz +%= state.az +% direction.vz;
        } else {
            state.fx +%= state.ax;
            state.fy +%= state.ay;
            state.fz +%= state.az;
        }

        cur = psx.get(n.next);
    }
}
