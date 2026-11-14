//! Semi-transparent actor model draw (D2: 4B16C.s; pc/src/actor_packets.c).
const common = @import("common");
const psx = common.psx;

const NativeTake = *const fn (c_int, ?*const anyopaque, ?*const anyopaque, ?*const anyopaque, ?*const anyopaque) callconv(.c) c_int;

/// orig: func_800B5C30 (pc/src/actor_packets.c)
/// The blended variant of func_800B4594 (object byte 9 selects the blend mode, every vertex takes the object colour): drawn through the native list, no packets are built.
pub fn buildBlendedActorPackets(projected: [*]c_uint, object: [*]u8, color: [*]const c_uint, model: [*]u8) callconv(.c) void {
    if (psx.weak(NativeTake, "pc_object_native_take")) |take| _ = take(3, projected, object, model, color);
}
