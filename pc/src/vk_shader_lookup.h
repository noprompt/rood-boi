/* The Vulkan renderer's shader code by name (shader hot reload,
 * pc/docs/Vulkan_Renderer.md "Hot reload"): every module is made through
 * VK_SHADER(name) (vk_core.h), which takes the override set for `name`, a
 * stage compiled in the running game, else the SPIR-V embedded at build time
 * (vk_shaders.h). No Vulkan here: pc/tests/shader_compiler_probe.cpp links it. */
#pragma once
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* The code for `name` (the generated stem, e.g. "scaled_frag"): its override
 * if one is set (*bytes becomes its size), else `code`. */
const uint32_t* vk_shader_code(const char* name, const uint32_t* code, size_t* bytes);
/* Sets (copies) or, with code NULL, clears the override for `name`. */
void vk_shader_override(const char* name, const uint32_t* code, size_t bytes);
void vk_shader_overrides_clear(void);
/* The SPIR-V built into the game for `name` (vk_shaders.h), else NULL. */
const uint32_t* vk_shader_builtin(const char* name, size_t* bytes);
/* The overridden names in the order set; NULL past the last. */
const char* vk_shader_override_name(int index);

#ifdef __cplusplus
}
#endif
