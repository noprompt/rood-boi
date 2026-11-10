//! Per-vertex-colour actor packets (D2: 4B16C.s; oracle pc/src/actor_packets.c).
const c = @import("c_actor_packets");
const common = @import("common");
const pad = @import("common").pad;
const psx = common.psx;

const NativeDraw = *const fn (c_int, ?*const anyopaque, ?*const anyopaque, ?*const anyopaque, ?*const anyopaque, ?[*]c_uint) callconv(.c) void;

/// orig: func_800B4594 (pc/src/actor_packets.c)
/// Builds the actor's GT3/GT4 packets from the projected vertices (screen
/// words, then depths 0xC00 bytes on) and the model's polygon records at
/// model +0x3C, with the packet cursor and ordering table from the
/// packet cursor and ordering table and the texture word at 0x1F800390, then moves
/// the cursor on and hands the new packets to the native renderer. `unused`
/// is not read.
pub fn buildActorPackets(projected: [*]c_uint, actor: [*]u8, unused: ?*anyopaque, model: [*]u8) callconv(.c) void {
    _ = unused;
    // The cursor, table and polygon words are guest addresses the C uses as-is (any alignment).
    @setRuntimeSafety(false);
    const texture = @as(*c_uint, @ptrFromInt(pad.addr(0x390))).*;
    const scratch = common.scratch.get();
    const start: ?[*]c_uint = @ptrFromInt(@intFromPtr(scratch.unk0));
    const ot: ?[*]c_uint = @ptrFromInt(@intFromPtr(scratch.unk4));
    const polygons: ?[*]const c_uint = @ptrFromInt(@intFromPtr(model) +% psx.byteAt(u32, model, 0x3c).*);
    const end = c.pc_actor_packets(start, ot, projected, projected + 0x300, polygons, @ptrCast(@alignCast(actor + 2)), texture & 0xffff, texture >> 16);
    scratch.unk0 = end;
    if (psx.weak(NativeDraw, "pc_object_native_draw")) |draw| draw(1, projected, actor, model, null, start);
}
