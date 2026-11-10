/* A sprite as a draw item (pc/src/draw_items.h), what vs_battle_setSprite and its kin made as packets: placed in the
 * ordering table at the slot `ot` (NULL: vs_scratch.unk8, as vs_battle_setSpriteDefault linked) (a marker, as the packet linked there), `brightness` the grey it is drawn in (bit 7 of it
 * set again as bit 8: semi-transparent, as the packet's code took it), its place and size (x low, y high; w low, h high), the
 * draw mode as a GP0 E1 word (vs_getTpage; VS_SPRITE_PAGE: the default texture page; 0: the GPU's) and the texels and CLUT
 * (u, v, CLUT words as vs_getUV0Clut packs them). Returns the item, whose command word ui_text keys on
 * (vs_battle_spriteCommand). Defined in pc/src/battle_helpers.c. */
#ifndef VS_SPRITE_ITEM_H
#define VS_SPRITE_ITEM_H
#define VS_SPRITE_PAGE 0xE100000C
int vs_battle_spriteItem(unsigned* ot, int brightness, int xy, int wh, int mode, int uv_clut);
const void* vs_battle_spriteCommand(int item);
int vs_battle_spriteColor(int item, int colour); /* its colour as a word: 0xBBGGRR, bit 25 semi-transparent; returns the item */
#endif
