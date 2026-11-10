/* Host-only room submission candidate retained from decompilation work:
 * .work/ultracode/r8-146C/8ac78/v16.c (see docs/decomp-blockers.md).
 * Near-matching, not an original-binary match; minimap branches need runtime QA.
 * Included in 146C.c to use the same private types and globals. */
extern int D_800F1BA0;
void func_8008DF14(void);
void func_8009627C(void);
void func_8008C0C0(void);
void func_80091B04(void);
void func_8008CEB0(void);
void func_80090EEC(void);
void func_8008B1FC(void*);
void func_8008B590(MATRIX*, int);
void func_80098F8C(vs_battle_scene*);
/* Widescreen: the area map is anchored to the right edge of the screen
 * (gpu_hw.c); its rooms are projected without the GTE's Hor+ narrowing so
 * they scale with their frame and stay inside it at every rotation. */
extern int pc_gte_anchored;
extern void pc_hw_anchor_packets(const void* start, const void* end, int anchor)
    __attribute__((weak));
#define PC_ANCHOR_RIGHT 2
/* Host-only query for the interactive fog (dev_state.c pc_dev_battle_action,
 * fog_sim.cpp): the battle action running now (D_800F196C 2), one at a time
 * for every actor: its performer, action, phase (_cameraMode: 5 an effect
 * action started casting, 7 a swing or a release started (func_80070278, once
 * per swing, chain step and release), 8 a chain step succeeded, 9 ending),
 * the chain step, its kind (vs_main_actions: type and unk2_0, 0 a plain
 * attack), its aim point (unk844, world units) and its first target, the
 * actor func_800780A8 frames with the performer (unk4C[0] when it has
 * targets and that target is an actor; -1: none, or a point). */
/* Host-only query for the depth of field's camera subject (post_profile.cpp,
 * dof_focus `subject`; dev_state.c pc_dev_battle_camera): what BATTLE's camera
 * steps toward now, read the way func_8006E640 reads it in the action state
 * (D_800F196C 2): in _cameraMode 1 and 3 the chosen target candidate
 * (unk29C0[unk298D], while one is chosen: the targeting sphere's), in mode 2
 * the area point (unk2998); and the camera's look-at (vs_view.camera,
 * world units). out: [0] D_800F196C (-1: no battle state), [1] _cameraMode,
 * [2] a target candidate chosen, [3..5] its point (the body part's, or the
 * actor's: func_800719FC's list), [6] an area point, [7..9] it, [10..12] the
 * look-at, [13] the candidate's actor slot (unk9). Reads only. */
/* Host-only queries for gameplay_walls.c (smart cutaway walls). */
extern char D_800F4C34; /* the event runner's state (4A0A8.c): nonzero while an event loads or runs */
/* The running event's id as func_800BEB10 gives it ((source << 12) | event file;
 * source 0 the zone's event file, 1 the room's entry script, 2 a door's), or
 * -1 when none runs (post_profile.cpp: `post event.<id>` items). */
extern u_short D_800F4BE0;
/* The event interpreter's place, for the cutscene player (cutscene.cpp): state[0] the runner's
 * state (D_800F4C34: 0 none, 1-3 loading, 4 running), state[1] the skip state (D_800F4C2C: 0 not
 * skippable, 1 a skippable part, 2 skipping); per script thread (0 the main one, 1-3 forked) its
 * offset in the script buffer (-1: not running) and the opcode there, and that opcode's handler. */
extern u_char* D_800F4C38[];
extern int (*_opcodeFunctionTable[256])(u_char*, short);
/* Operand sizes come from the interpreter's own table (573B8.c: func_800BFE34).
 * These are raw operand bytes; actor resolution is limited to source-verified handlers. */
extern u_char D_800E9C30[];
extern int func_800BFE50(u_short);
/* What the running event waits for from the player (the cutscene viewer's auto-advance, cutscene.cpp):
 * the PS1 pad bits a thread waits on (op 0x15, vs_battle_script_buttonPressed: its mask; op 0x11,
 * vs_battle_script_showTextBox, a dialogue box shown and not yet answered: Circle; op 0x59 with its screen up:
 * Circle), 0 when nothing.
 * A box with choices (vs_main_stateFlags.textBoxSelection) takes the default answer. */
extern char vs_battle_textBoxStatuses[];
extern char D_800F4BF8;
/* The battle camera's target (weapon drawn, a target chosen: the point the
 * camera follows in its modes 1 and 3), as func_8007ACB0's caller reads it. */

/* Declared for the Zig's c module (the C bodies that declared them are gone). */
void anchor_map(void* start);
