/* Native packet emission from BATTLE/4B16C.s func_800B3CF0.
 * The projected arrays, packed polygon records and 24-bit OT links stay intact. */
#include <sys/types.h>
#include <libgte.h>
#include <inline_c.h>
extern void pc_unimplemented(const char*);

static unsigned vertex_index(unsigned offset)
{
    if ((offset & 3) || offset >= 0xc00)
        pc_unimplemented("weapon polygon vertex offset");
    return offset >> 2;
}
static int area(const unsigned* xy)
{
    MTC2(xy[0], 12);
    MTC2(xy[1], 13);
    MTC2(xy[2], 14);
    gte_nclip();
    return MFC2(24);
}
static unsigned average_depth(const unsigned* z, int quad)
{
    if (quad)
        return (z[0] + z[1] + z[2] + z[3]) >> 4;
    MTC2(z[0], 17);
    MTC2(z[1], 18);
    MTC2(z[2], 19);
    gte_avsz3();
    return MFC2(7);
}
static unsigned* emit(unsigned* packet, unsigned* ot, int bucket, unsigned color,
    unsigned tpage, unsigned clut, const unsigned* xy, const unsigned* uv, int quad)
{
    unsigned words = quad ? 9 : 7;
    unsigned* head = ot + bucket;
    packet[0] = (*head & 0xffffff) | (words << 24);
    *head = (*head & 0xff000000) | (psx_to_int(unsigned, packet) & 0xffffff);
    packet[1] = color;
    for (int i = 0; i < (quad ? 4 : 3); i++) {
        packet[2 + i * 2] = xy[i];
        packet[3 + i * 2] = uv[i];
    }
    packet[3] |= clut << 16;
    packet[5] |= tpage << 16;
    return packet + words + 1;
}
/* Pick the original non-planar quad diagonal using the GTE OP determinant.
 * Arithmetic below is explicitly 32-bit wrapping, like the MIPS multiplies. */
static int split_diagonal(const unsigned* xy, const unsigned* z)
{
    int x0 = (short)xy[0], y0 = (short)(xy[0] >> 16);
    CTC2((short)xy[2] - x0, 0);
    CTC2((short)(xy[2] >> 16) - y0, 2);
    CTC2(z[2] - z[0], 4);
    MTC2((short)xy[1] - x0, 9);
    MTC2((short)(xy[1] >> 16) - y0, 10);
    MTC2(z[1] - z[0], 11);
    gte_op0();
    unsigned dot = ((unsigned)((short)xy[3] - x0) * MFC2(25))
                 + ((unsigned)((short)(xy[3] >> 16) - y0) * MFC2(26))
                 + ((z[3] - z[0]) * MFC2(27));
    return (int)(0u - dot) > 0;
}
static unsigned* split_quad(unsigned* packet, unsigned* ot, unsigned color,
    unsigned tpage, unsigned clut, const unsigned* xy, const unsigned* z,
    const unsigned* uv)
{
    static const unsigned indices[2][2][3] = { { { 0, 1, 3 }, { 0, 3, 2 } },
        { { 0, 1, 2 }, { 1, 3, 2 } } };
    int diagonal = split_diagonal(xy, z);
    for (unsigned face = 0; face < 2; ++face) {
        unsigned tx[3], tz[3], tu[3];
        for (unsigned i = 0; i < 3; ++i) {
            unsigned n = indices[diagonal][face][i];
            tx[i] = xy[n];
            tz[i] = z[n];
            tu[i] = uv[n];
        }
        if (area(tx) <= 0) {
            /* The original reserves an unlinked slot in this one branch. */
            if (diagonal == 0 && face == 1)
                packet += 8;
            continue;
        }
        unsigned depth = average_depth(tz, 0) + 4;
        if (depth < 0x7c0)
            packet = emit(packet, ot, (int)depth - 5, (color & 0xffffff) | 0x24000000,
                tpage, clut, tx, tu, 0);
    }
    return packet;
}
unsigned* pc_weapon_packets(unsigned* packet, unsigned* ot, const unsigned* projected,
    const unsigned* depths, const unsigned* polygons, const unsigned short counts[3],
    unsigned color, unsigned tpage, unsigned clut)
{
    for (unsigned kind = 0; kind < 3; ++kind) {
        for (unsigned face = 0; face < counts[kind]; ++face) {
            unsigned header = polygons[0];
            int quad = kind == 1 || (kind == 2 && (header & 255) == 0x2c);
            unsigned flags = kind == 2 ? header >> 16 : 0;
            unsigned xy[4], z[4], uv[4];
            unsigned offsets[4] = { polygons[1] & 0xffff, polygons[1] >> 16,
                polygons[2] & 0xffff, polygons[2] >> 16 };
            for (int i = 0; i < (quad ? 4 : 3); i++) {
                unsigned index = vertex_index(offsets[i]);
                xy[i] = projected[index];
                z[i] = depths[index];
            }
            unsigned stride = quad ? 5 : 4;
            if (!(flags & 1) && area(xy) <= 0) {
                if (kind == 2) {
                    unsigned bytes = (header >> 8) & 255;
                    if (bytes < 16 || (bytes & 3))
                        pc_unimplemented("weapon polygon stride");
                    stride = bytes / 4;
                }
                polygons += stride;
                continue;
            }

            uv[0] = polygons[3] & 0xffff;
            uv[1] = polygons[3] >> 16;
            uv[2] = quad ? polygons[4] : polygons[2] >> 16;
            uv[3] = quad ? polygons[4] >> 16 : 0;
            if ((flags & 3) == 3) {
                if (!quad)
                    pc_unimplemented("split flag on non-quad weapon face");
                packet = split_quad(packet, ot, color, tpage, clut, xy, z, uv);
                polygons += 5;
                continue;
            }
            unsigned depth =
                average_depth(z, quad) + (kind == 2 ? ((flags >> 2) & 3) * 4 : 0);
            if (depth < 0x7c0) {
                unsigned code = quad ? 0x2c : 0x24;
                if (flags & 16)
                    code |= 2;
                packet = emit(packet, ot, (int)depth - (kind == 2 ? 5 : 1),
                    (color & 0xffffff) | (code << 24), tpage | (flags & 0x60), clut, xy,
                    uv, quad);
            }
            polygons += stride;
        }
    }
    return packet;
}
/* actor_native.c: the native list for the model just built (weak: probes);
 * `kind` 0 for func_800B3CF0, 2 for func_800B516C. */
extern void pc_object_native_draw(int kind, const void* projected, const void* object, const void* model,
    const void* color, unsigned* start) __attribute__((weak));
void func_800B3CF0(void* projected, void* object, void* color, void* model);


/* ---------------------------------------------------------------------------
 * 4B16C.s func_800B516C: the weapon renderer used while the actor is in a
 * special state (e.g. paused). Unlike func_800B3CF0 it walks each polygon
 * section in material groups (8 counts at the model, then the remainder),
 * swaps in the alternate CLUT (+0x480) for groups flagged in object byte 0x64,
 * and makes polygons semi-transparent when object byte 9 selects a blend
 * mode (1-6 subtractive tpage 0x40, 7+ additive 0x20). OT buckets: triangles
 * and quads depth - 1, mixed records depth - 5 plus their bias; split quads
 * depth - 1. Packets are written in the original order, including the slot
 * the split path reserves without linking. */
struct blend_state {
    unsigned* packet;
    unsigned* ot;
    unsigned color, tpage_hi, blend, clut_hi;
};
static void link_packet(struct blend_state* s, unsigned* packet, int bucket, unsigned words)
{
    unsigned* head = s->ot + bucket;
    packet[0] = (*head & 0xffffff) | (words << 24);
    *head = (*head & 0xff000000) | (psx_to_int(unsigned, packet) & 0xffffff);
}
/* Group walk shared by the three sections: returns the CLUT word (<< 16) and
 * count of the next non-empty group, or 0 when the section is finished. */
struct group_walk {
    int counter, total, done;
    const unsigned short* counts;
};
static int nclip3(unsigned a, unsigned b, unsigned c)
{
    MTC2(a, 12);
    MTC2(b, 13);
    MTC2(c, 14);
    gte_nclip();
    return MFC2(24);
}
static unsigned avsz3(unsigned a, unsigned b, unsigned c)
{
    MTC2(a, 17);
    MTC2(b, 18);
    MTC2(c, 19);
    gte_avsz3();
    return MFC2(7);
}
void func_800B516C(void* projected, void* object, void* color, void* model);

