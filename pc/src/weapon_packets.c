/* BATTLE/4B16C.s func_800B3CF0 and func_800B516C: the weapon and shield models. No packets are built: the Zig
 * (game/battle/pc/build_weapon_packets.zig, build_blended_weapon_packets.zig) draws them through the native list
 * (actor_native.c pc_object_native_take). */
void func_800B3CF0(void* projected, void* object, void* color, void* model);
void func_800B516C(void* projected, void* object, void* color, void* model);
