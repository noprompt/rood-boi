/* The Vulkan renderer's shaders compiled in the running game (shader hot
 * reload, pc/docs/Vulkan_Renderer.md "Hot reload"): the vendored glslang
 * linked as a library, with the options pc/tools/vk_shaders.py gives the
 * standalone compiler (-V --target-env vulkan1.3, includes from the stage's
 * folder and pc/third_party/smaa), so a stage compiles to the same SPIR-V
 * as the build's (pc/tests/shader_compiler_probe.cpp checks it). */
#pragma once
#include <stdint.h>

#include <string>
#include <vector>

namespace shader_compiler {

struct Result {
    bool ok = false;
    std::vector<uint32_t> spirv;
    /* On failure, `file:line: message` lines (else glslang's own log). */
    std::string log;
    /* Every file read: the stage and each include, recursively. */
    std::vector<std::string> files;
};

/* What a stage's SPIR-V declares to the pipeline around it: the layout
 * contract a replacement must keep (the C code made the descriptor set and
 * push constant layouts, and the attachments, for the built-in stage). */
struct Interface {
    /* set << 16 | binding -> kind: 1 sampler, 2 combined image sampler, 3 sampled
     * image, 4 storage image, 5 uniform buffer, 6 storage buffer, 7 texel
     * buffer, 8 acceleration structure, 9 input attachment; + 100 * array size
     * when arrayed. */
    std::vector<std::pair<uint32_t, int>> bindings;
    int push_bytes = 0;            /* the push constant block's size (0: none) */
    std::vector<int> inputs, outputs; /* the stage's input and output locations (vertex inputs, fragment outputs) */
    bool valid = false;
};
Interface reflect(const uint32_t* spirv, size_t words);
/* "" when `replacement` keeps `builtin`'s contract (it may use less), else why not. */
std::string contract_mismatch(const Interface& builtin, const Interface& replacement);

/* glslang's process set-up, once (any thread may compile after). */
bool init();
void shutdown();
/* A stage file, <name>.<vert|geom|frag|comp>; thread safe. */
Result compile(const std::string& path);

} // namespace shader_compiler
