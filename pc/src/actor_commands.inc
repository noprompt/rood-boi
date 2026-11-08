/* Host-only retained candidate: battle-146C/75554/a6.full.c.
 * See docs/decomp-blockers.md. Original PS1 assembly remains unchanged. */

typedef struct {
    u_int state : 8;
    u_int command : 8;
    u_int target : 8;
    u_int effect : 2;
    u_int camera : 2;
    u_int unk28 : 4;
} actorCommandHeader;

