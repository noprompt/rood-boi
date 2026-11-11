/* Overlay statics: restart an overlay's native data on every load.
 *
 * On the PS1 an overlay's statics live inside its image, so each disc load
 * (e.g. MAINMENU.PRG at every menu open) brings them back to their initial
 * values. Natively compiled, they sit in host .data/.bss and would persist.
 * build_boot.py moves each overlay's .data/.bss into its own sections and
 * generates pc_overlay_statics[] from their bounds; here the initial .data
 * is snapshotted at startup and restored (and .bss cleared) whenever the
 * disc read that loads that overlay file is serviced. ROOD_OVERLAY_STATICS=0
 * turns this off (natively persistent statics, for comparison). */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct pc_overlay_statics {
    const char* path; /* file on the disc, e.g. "MENU/MAINMENU.PRG" */
    int lba;          /* its first sector: the game's own VS_<NAME>_LBA, written by build_boot.py */
    char *data_start, *data_end, *bss_start, *bss_end;
};
extern const struct pc_overlay_statics pc_overlay_statics[];
extern const int pc_overlay_statics_count;
extern void pc_unimplemented(const char*) __attribute__((noreturn));

static char** snapshots; /* per file: its initial .data (shared by byte-identical copies) */

void pc_overlay_statics_init(void)
{
    const char* enabled = getenv("ROOD_OVERLAY_STATICS");
    if (enabled && !strcmp(enabled, "0")) {
        fprintf(stderr, "[overlay] statics restart disabled (ROOD_OVERLAY_STATICS=0)\n");
        return;
    }
    snapshots = calloc(pc_overlay_statics_count ? pc_overlay_statics_count : 1, sizeof *snapshots);
    if (!snapshots) {
        perror("overlay statics");
        exit(1);
    }
    size_t bytes = 0;
    for (int i = 0; i < pc_overlay_statics_count; i++) {
        const struct pc_overlay_statics* o = &pc_overlay_statics[i];
        /* Byte-identical overlay copies share one region: share its snapshot. */
        for (int j = 0; j < i && !snapshots[i]; j++)
            if (pc_overlay_statics[j].data_start == o->data_start)
                snapshots[i] = snapshots[j];
        if (!snapshots[i] && o->data_end > o->data_start) {
            snapshots[i] = malloc(o->data_end - o->data_start);
            if (!snapshots[i])
                pc_unimplemented("overlay statics snapshot");
            memcpy(snapshots[i], o->data_start, o->data_end - o->data_start);
            bytes += o->data_end - o->data_start;
        }
    }
    fprintf(stderr, "[overlay] %d overlay files, %zu bytes of initial statics\n",
        pc_overlay_statics_count, bytes);
}

/* A disc read starting at `lba` was serviced: restart the statics of the
 * overlay file that begins there, as reloading its image does on the PS1. */
void pc_overlay_statics_loaded(int lba)
{
    if (!snapshots)
        return;
    for (int i = 0; i < pc_overlay_statics_count; i++) {
        const struct pc_overlay_statics* o = &pc_overlay_statics[i];
        if (o->lba != lba)
            continue;
        if (o->data_end > o->data_start)
            memcpy(o->data_start, snapshots[i], o->data_end - o->data_start);
        memset(o->bss_start, 0, o->bss_end - o->bss_start);
    }
}
