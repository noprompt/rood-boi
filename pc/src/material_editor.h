// What the material editor (material_editor.cpp, Details > Material) shares
// with the Material review window (material_review.cpp).
#ifndef ROOD_MATERIAL_EDITOR_H
#define ROOD_MATERIAL_EDITOR_H
#include <string>
#include "materials.h"

/* The entry's response controls (preset, roughness, specular, metal, the
 * height estimate, relief): whether they changed it. */
bool material_entry_fields(materials::Entry& e);
/* Selects an entry in Details > Material. */
void material_editor_select(const std::string& id);

extern "C" {
/* The Material review (material_review.cpp): Window > Material review. */
extern bool pc_material_review_open;
void pc_material_review_window(void);
void pc_material_review_frame(void); /* every overlay frame: the preview and the highlight follow the window */
int pc_material_review_rpc(const char* params, char* out, int size);
}
#endif
