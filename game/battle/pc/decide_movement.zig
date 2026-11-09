//! The per-frame movement decision (D2: 72B70.s; oracle pc/src/battle_movement.c).
const ai = @import("views_71618");
const c = @import("c_battle_movement");
const psx = @import("common").psx;

/// orig: func_800DB820 (pc/src/battle_movement.c)
/// Per-frame movement decision. Dispatch (func_800DAD9C), unstick
/// (func_800DB0BC) and the state's own callback at 0x68 each may claim the
/// frame; otherwise the actor wanders. The callback must be a native
/// function (pc_require_native_callback checks it).
pub fn decideMovement(state: *ai.vs_battle_aiState) callconv(.c) void {
    if (c.func_800DAD9C(state) != 0 or c.func_800DB0BC(state) != 0) return;
    const callback: ?*const fn (?*anyopaque) callconv(.c) c_int = @ptrCast(state.callback);
    if (callback) |call| {
        c.pc_require_native_callback(psx.addr(call), "actor movement callback", 0);
        if (call(state) != 0) return;
    }
    c.func_800DB5B0(state);
}
