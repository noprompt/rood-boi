#include "texture_t.h"
#include "pc/src/game/menufLeaf.h"

#ifndef PC_MENUF_CALL /* (the classic hook: MENUF's 3B8.c, ENDING's D4.c) */
#define PC_MENUF_CALL(op, x, y, tex, a, b, colours)
#endif

void _renderTextureFadeInTint(int x, int y, int texId, P_CODE colors[])
{
    pc_item* poly;

    PC_MENUF_CALL(TINT, x, y, texId, 0, 0, colors);

    if (colors[0].code == 0) {
        return;
    }

    poly = _leafItem(PC_ITEM_POLY, 4, PC_ITEM_TEXTURED | PC_ITEM_SHADED | PC_ITEM_SEMI);
    _leafQuad(poly, x, y, &_disMap[texId]);

    if (colors[0].code < 8) {
        _leafRgb(poly, 0, (colors[0].r0 * colors[0].code) / 8, (colors[0].g0 * colors[0].code) / 8,
            (colors[0].b0 * colors[0].code) / 8);
        _leafRgb(poly, 1, (colors[1].r0 * colors[0].code) / 8, (colors[1].g0 * colors[0].code) / 8,
            (colors[1].b0 * colors[0].code) / 8);
        _leafRgb(poly, 2, (colors[0].r0 * colors[0].code) / 8, (colors[0].g0 * colors[0].code) / 8,
            (colors[0].b0 * colors[0].code) / 8);
        _leafRgb(poly, 3, (colors[1].r0 * colors[0].code) / 8, (colors[1].g0 * colors[0].code) / 8,
            (colors[1].b0 * colors[0].code) / 8);
    } else {
        _leafRgb(poly, 0, colors[0].r0, colors[0].g0, colors[0].b0);
        _leafRgb(poly, 1, colors[1].r0, colors[1].g0, colors[1].b0);
        _leafRgb(poly, 2, colors[0].r0, colors[0].g0, colors[0].b0);
        _leafRgb(poly, 3, colors[1].r0, colors[1].g0, colors[1].b0);
    }

    if (colors[0].code < 8) {
        poly->clut = _disMap[texId].clut + 1;
        poly->mode = _disMap[texId].tpage | 0x20;
    } else {
        poly->clut = _disMap[texId].clut;
        poly->mode = _disMap[texId].tpage;
    }
}

static inline int _adjust(int component, int weight)
{
    int ret = (component * weight) + ((4 - weight) * 192);
    return ret / 4;
}

void _renderTexturePopIn(int x, int y, int texId, P_CODE colors[])
{
    pc_item* poly;

    PC_MENUF_CALL(POP, x, y, texId, 0, 0, colors);

    if (colors[0].code != 0) {
        poly = _leafItem(PC_ITEM_POLY, 4, PC_ITEM_TEXTURED | PC_ITEM_SHADED | PC_ITEM_SEMI);
        _leafQuad(poly, x, y, &_disMap[texId]);

        if (colors[0].code < 8) {
            _leafRgb(poly, 0, (colors[0].r0 * colors[0].code) / 8, (colors[0].g0 * colors[0].code) / 8,
                (colors[0].b0 * colors[0].code) / 8);
            _leafRgb(poly, 1, (colors[1].r0 * colors[0].code) / 8, (colors[1].g0 * colors[0].code) / 8,
                (colors[1].b0 * colors[0].code) / 8);
            _leafRgb(poly, 2, (colors[0].r0 * colors[0].code) / 8, (colors[0].g0 * colors[0].code) / 8,
                (colors[0].b0 * colors[0].code) / 8);
            _leafRgb(poly, 3, (colors[1].r0 * colors[0].code) / 8, (colors[1].g0 * colors[0].code) / 8,
                (colors[1].b0 * colors[0].code) / 8);
        } else if (colors[0].code == 8) {
            _leafRgb(poly, 0, 192, 192, 192);
            _leafRgb(poly, 1, 192, 192, 192);
            _leafRgb(poly, 2, 192, 192, 192);
            _leafRgb(poly, 3, 192, 192, 192);
        } else if (colors[0].code == 9) {
            _leafRgb(poly, 0, 224, 224, 224);
            _leafRgb(poly, 1, 224, 224, 224);
            _leafRgb(poly, 2, 224, 224, 224);
            _leafRgb(poly, 3, 224, 224, 224);
        } else if (colors[0].code < 14) {
            int temp_a0 = colors[0].code - 10;
            _leafRgb(poly, 0, _adjust(colors[0].r0, temp_a0), _adjust(colors[0].g0, temp_a0),
                _adjust(colors[0].b0, temp_a0));
            _leafRgb(poly, 1, _adjust(colors[1].r0, temp_a0), _adjust(colors[1].g0, temp_a0),
                _adjust(colors[1].b0, temp_a0));
            _leafRgb(poly, 2, _adjust(colors[0].r0, temp_a0), _adjust(colors[0].g0, temp_a0),
                _adjust(colors[0].b0, temp_a0));
            _leafRgb(poly, 3, _adjust(colors[1].r0, temp_a0), _adjust(colors[1].g0, temp_a0),
                _adjust(colors[1].b0, temp_a0));
        } else {
            _leafRgb(poly, 0, colors[0].r0, colors[0].g0, colors[0].b0);
            _leafRgb(poly, 1, colors[1].r0, colors[1].g0, colors[1].b0);
            _leafRgb(poly, 2, colors[0].r0, colors[0].g0, colors[0].b0);
            _leafRgb(poly, 3, colors[1].r0, colors[1].g0, colors[1].b0);
        }

        if (colors[0].code < 10) {
            poly->clut = _disMap[texId].clut + getClut(16, 0);
            poly->mode = _disMap[texId].tpage | getTPage(0, 1, 0, 0);
        } else {
            poly->clut = _disMap[texId].clut;
            poly->mode = _disMap[texId].tpage;
        }
    }
}

void _renderTextureWipe(int x, int y, int texId, P_CODE arg3[], int arg4)
{
    int temp_a1;
    int var_a0;
    int i;
    char var_s6;
    pc_item* poly;

    PC_MENUF_CALL(WIPE, x, y, texId, arg4, 0, arg3);

    if ((x + _disMap[texId].w) < (arg4 - 64)) {
        poly = _leafItem(PC_ITEM_POLY, 4, PC_ITEM_TEXTURED | PC_ITEM_SHADED | PC_ITEM_SEMI);
        _leafQuad(poly, x, y, &_disMap[texId]);
        _leafRgb(poly, 0, arg3[0].r0, arg3[0].g0, arg3[0].b0);
        _leafRgb(poly, 1, arg3[1].r0, arg3[1].g0, arg3[1].b0);
        _leafRgb(poly, 2, arg3[0].r0, arg3[0].g0, arg3[0].b0);
        _leafRgb(poly, 3, arg3[1].r0, arg3[1].g0, arg3[1].b0);

        poly->clut = _disMap[texId].clut;
        poly->mode = _disMap[texId].tpage;
        return;
    }

    if (x < arg4) {

        var_s6 = _disMap[texId].x;

        for (i = 0; i < _disMap[texId].w; i += 12, x += 12, var_s6 += 12) {

            var_a0 = 12;

            if ((i + 12) >= _disMap[texId].w) {
                var_a0 = _disMap[texId].w - i;
            }

            poly = _leafItem(PC_ITEM_POLY, 4, PC_ITEM_TEXTURED | PC_ITEM_SHADED | PC_ITEM_SEMI);
            temp_a1 = x + var_a0;
            poly->x[0] = (short)x, poly->y[0] = (short)y;
            poly->x[1] = (short)temp_a1, poly->y[1] = (short)y;
            poly->x[2] = (short)x, poly->y[2] = (short)(_disMap[texId].h + y);
            poly->x[3] = (short)temp_a1, poly->y[3] = (short)(_disMap[texId].h + y);
            poly->u[0] = (unsigned char)var_s6, poly->v[0] = (unsigned char)_disMap[texId].y;
            poly->u[1] = (unsigned char)(var_s6 + var_a0), poly->v[1] = (unsigned char)_disMap[texId].y;
            poly->u[2] = (unsigned char)var_s6, poly->v[2] = (unsigned char)(_disMap[texId].y + _disMap[texId].h);
            poly->u[3] = (unsigned char)(var_s6 + var_a0), poly->v[3] = (unsigned char)(_disMap[texId].y + _disMap[texId].h);

            var_a0 = arg4 - x;

            if (var_a0 > 64) {
                var_a0 = 64;
            }

            if (var_a0 < 0) {
                var_a0 = 0;
            }

            _leafRgb(poly, 0, (arg3[0].r0 * var_a0) / 64, (arg3[0].g0 * var_a0) / 64, (arg3[0].b0 * var_a0) / 64);
            _leafRgb(poly, 2, (arg3[0].r0 * var_a0) / 64, (arg3[0].g0 * var_a0) / 64, (arg3[0].b0 * var_a0) / 64);

            var_a0 = arg4 - temp_a1;

            if (var_a0 > 64) {
                var_a0 = 64;
            }

            if (var_a0 < 0) {
                var_a0 = 0;
            }

            _leafRgb(poly, 1, (arg3[1].r0 * var_a0) / 64, (arg3[1].g0 * var_a0) / 64, (arg3[1].b0 * var_a0) / 64);
            _leafRgb(poly, 3, (arg3[1].r0 * var_a0) / 64, (arg3[1].g0 * var_a0) / 64, (arg3[1].b0 * var_a0) / 64);

            poly->clut = (_disMap[texId].clut + 1);
            poly->mode = (_disMap[texId].tpage | 0x20);
        }
    }
}
