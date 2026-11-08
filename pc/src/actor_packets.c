/* BATTLE/4B16C.s func_800B4594: per-vertex-colored character GT3/GT4 packets.
 * Keep the original packed records, material flags and depth bias. */
#include "psx_types.h" /* psx_load/psx_store: 4-byte guest pointers */
#include <sys/types.h>
#include <libgte.h>
#include <inline_c.h>
extern void pc_unimplemented(const char*);
static unsigned actor_vertex(unsigned offset)
{
    if ((offset & 3) || offset >= 0xc00)
        pc_unimplemented("actor polygon vertex offset");
    return offset >> 2;
}
unsigned* pc_actor_packets(unsigned* packet, unsigned* ot, const unsigned* projected,
    const unsigned* depths, const unsigned* polygons, const unsigned short counts[3],
    unsigned tpage, unsigned clut)
{
    for (unsigned kind = 0; kind < 3; ++kind) {
        unsigned flags = kind == 2 && counts[kind] ? polygons[4] >> 24 : 0;
        for (unsigned face = 0; face < counts[kind]; ++face) {
            int quad = kind == 1 || (kind == 2 && (polygons[2] >> 24) == 0x3c);
            unsigned count = quad ? 4 : 3;
            unsigned index[4] = { actor_vertex(polygons[0] & 0xffff),
                actor_vertex(polygons[0] >> 16), actor_vertex(polygons[1] & 0xffff), 0 };
            if (quad)
                index[3] = actor_vertex(polygons[1] >> 16);
            int culled = 0;
            if (!(flags & 1)) {
                MTC2(projected[index[0]], 12);
                MTC2(projected[index[1]], 13);
                MTC2(projected[index[2]], 14);
                gte_nclip();
                culled = (int)MFC2(24) <= 0;
            }
            if (culled) {
                unsigned stride = kind == 2 ? polygons[3] >> 24 : (quad ? 32 : 24);
                if (stride < 24 || (stride & 3))
                    pc_unimplemented("actor polygon stride");
                polygons += stride / 4;
                /* The culled special-face branch reloads flags from word 0,
                 * whereas the emitted-face branch reloads word 4. */
                if (kind == 2 && face + 1 < counts[kind])
                    flags = polygons[0] >> 24;
                continue;
            }
            unsigned depth;
            if (quad) {
                depth = (depths[index[0]] + depths[index[1]] + depths[index[2]]
                            + depths[index[3]])
                     >> 4;
            } else {
                MTC2(depths[index[0]], 17);
                MTC2(depths[index[1]], 18);
                MTC2(depths[index[2]], 19);
                gte_avsz3();
                depth = MFC2(7);
            }
            if (kind == 2)
                depth += ((polygons[4] >> 26) & 3) * 4;
            if (depth < 0x7c0) {
                unsigned* head = ot + (int)depth - (kind == 2 ? 5 : 1);
                packet[0] = (*head & 0xffffff) | ((quad ? 12u : 9u) << 24);
                *head = (*head & 0xff000000) | (psx_to_int(unsigned, packet) & 0xffffff);
                unsigned uv01 = polygons[quad ? 6 : 5];
                unsigned uv23 = quad ? polygons[7] : polygons[1] >> 16;
                for (unsigned i = 0; i < count; ++i) {
                    packet[1 + i * 3] = polygons[2 + i];
                    packet[2 + i * 3] = projected[index[i]];
                }
                if (kind == 2)
                    packet[1] |= (flags & 16) << 21;
                packet[3] = (uv01 & 0xffff) | (clut << 16);
                packet[6] = (uv01 >> 16) | ((tpage | (flags & 0x60)) << 16);
                packet[9] = uv23;
                if (quad)
                    packet[12] = uv23 >> 16;
                packet += quad ? 13 : 10;
            }
            polygons += quad ? 8 : 6;
            if (kind == 2 && face + 1 < counts[kind])
                flags = polygons[4] >> 24;
        }
    }
    return packet;
}
/* actor_native.c: the native list for the model just built (weak: probes);
 * `kind` 1 for func_800B4594, 3 for func_800B5C30. */
extern void pc_object_native_draw(int kind, const void* projected, const void* object, const void* model,
    const void* color, unsigned* start) __attribute__((weak));
void func_800B4594(void* projected, void* actor, void* unused, void* model);


/* ---------------------------------------------------------------------------
 * 4B16C.s func_800B5C30: semi-transparent variant of func_800B4594. Records
 * are the same per-vertex-colored layouts, walked in material groups like
 * func_800B516C (8 counts at the model, then the remainder; CLUT + 0x480 for
 * groups flagged in object byte 0x64). When object byte 9 selects a blend
 * mode (1-6 tpage 0x40, 7+ 0x20) every vertex takes the object color and
 * the code becomes GT3/GT4 semi-transparent; mixed records keep their bias
 * byte in the third color. Differences from func_800B516C kept as-is: an
 * empty section does not skip its 8 counts, a depth-rejected triangle still
 * writes part of its packet, and the walk state is left in 0x1F80039C..A3. */
/* Next non-empty material group of a section, or 0 when it is finished. The
 * counter and running total live in scratchpad halfwords 0x39C/0x39E. */
void func_800B5C30(void* projected, void* object, void* color, void* model);

