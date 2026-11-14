/* BATTLE/4B16C.s func_800B4594 and func_800B5C30: the per-vertex-coloured character models. No packets are built: the Zig
 * (game/battle/pc/build_actor_packets.zig, build_blended_actor_packets.zig) draws them through the native list
 * (actor_native.c pc_object_native_take). */
void func_800B4594(void* projected, void* actor, void* unused, void* model);
void func_800B5C30(void* projected, void* object, void* color, void* model);
