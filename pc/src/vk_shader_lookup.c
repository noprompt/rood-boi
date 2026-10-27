/* Shader overrides by name (vk_shader_lookup.h). A handful at most (the
 * stages edited this session): a list searched in order. Main thread only:
 * the reload service (shader_reload.cpp) sets them between frames. */
#include "vk_shader_lookup.h"
#include <stdlib.h>
#include <string.h>
#define VK_SHADERS_DEFINE /* the embedded SPIR-V's one definition, and its table by name */
#include "vk_shaders.h"

typedef struct {
    char* name;
    uint32_t* code;
    size_t bytes;
} shader_override;
static shader_override* overrides;
static int override_count, override_capacity;

static int find(const char* name)
{
    for (int i = 0; i < override_count; i++)
        if (!strcmp(overrides[i].name, name))
            return i;
    return -1;
}

const uint32_t* vk_shader_code(const char* name, const uint32_t* code, size_t* bytes)
{
    int i = override_count ? find(name) : -1;
    if (i < 0)
        return code;
    *bytes = overrides[i].bytes;
    return overrides[i].code;
}

static void drop(int i)
{
    free(overrides[i].name);
    free(overrides[i].code);
    memmove(&overrides[i], &overrides[i + 1], (size_t)(override_count - i - 1) * sizeof *overrides);
    --override_count;
}

void vk_shader_override(const char* name, const uint32_t* code, size_t bytes)
{
    int i = find(name);
    if (!code) {
        if (i >= 0)
            drop(i);
        return;
    }
    uint32_t* copy = malloc(bytes ? bytes : 1);
    if (!copy)
        return;
    memcpy(copy, code, bytes);
    if (i >= 0) {
        free(overrides[i].code);
        overrides[i].code = copy, overrides[i].bytes = bytes;
        return;
    }
    if (override_count == override_capacity) {
        int capacity = override_capacity ? override_capacity * 2 : 16;
        shader_override* grown = realloc(overrides, (size_t)capacity * sizeof *grown);
        if (!grown) {
            free(copy);
            return;
        }
        overrides = grown, override_capacity = capacity;
    }
    char* kept = strdup(name);
    if (!kept) {
        free(copy);
        return;
    }
    overrides[override_count++] = (shader_override){ kept, copy, bytes };
}

void vk_shader_overrides_clear(void)
{
    while (override_count)
        drop(override_count - 1);
}

const char* vk_shader_override_name(int index)
{
    return index >= 0 && index < override_count ? overrides[index].name : NULL;
}

const uint32_t* vk_shader_builtin(const char* name, size_t* bytes)
{
    for (int i = 0; i < VK_SPV_COUNT; i++)
        if (!strcmp(vk_spv_table[i].name, name)) {
            *bytes = vk_spv_table[i].bytes;
            return vk_spv_table[i].code;
        }
    return NULL;
}
