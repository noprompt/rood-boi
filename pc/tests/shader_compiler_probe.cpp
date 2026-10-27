// The in-process shader compiler (pc/src/shader_compiler.cpp, shader hot
// reload) without the game: every stage in pc/shaders/vulkan compiles to the
// build's SPIR-V byte for byte (vk_shaders.py's, written by the standalone
// glslang), the files read are reported (includes too), and a broken stage
// fails with its file and line.
//
//     shader_compiler_probe <a copy of pc/shaders/vulkan> <pc/build/boot64/vk_spv> <scratch dir>
//
// (The copy: the contract cases write changed stages beside their includes.)
#include <dirent.h>
#include <stdio.h>
#include <string.h>

#include <algorithm>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#include "shader_compiler.h"
#include "vk_shader_lookup.h"

static int failures;
static void check(bool ok, const std::string& what)
{
    printf("%s %s\n", ok ? "ok:  " : "FAIL:", what.c_str());
    failures += !ok;
}

static bool read_file(const std::string& path, std::string& out)
{
    std::ifstream in(path, std::ios::binary);
    if (!in)
        return false;
    std::stringstream s;
    s << in.rdbuf();
    out = s.str();
    return true;
}

static std::string base_name(const std::string& path)
{
    size_t slash = path.find_last_of('/');
    return slash == std::string::npos ? path : path.substr(slash + 1);
}

/* Every stage file matches the build's SPIR-V. */
static void matches_the_build(const std::string& shaders, const std::string& spv)
{
    std::vector<std::string> stages;
    if (DIR* dir = opendir(shaders.c_str())) {
        while (dirent* e = readdir(dir)) {
            std::string name = e->d_name;
            size_t dot = name.rfind('.');
            std::string ext = dot == std::string::npos ? "" : name.substr(dot + 1);
            if (ext == "vert" || ext == "geom" || ext == "frag" || ext == "comp")
                stages.push_back(name);
        }
        closedir(dir);
    }
    std::sort(stages.begin(), stages.end());
    check(stages.size() > 40, "the stage files are there (" + std::to_string(stages.size()) + ")");
    int same = 0;
    for (const std::string& name : stages) {
        size_t dot = name.rfind('.');
        std::string stem = name.substr(0, dot) + "_" + name.substr(dot + 1), built;
        shader_compiler::Result r = shader_compiler::compile(shaders + "/" + name);
        if (!read_file(spv + "/" + stem + ".spv", built)) {
            check(false, name + ": no built " + stem + ".spv");
            continue;
        }
        bool equal = r.ok && r.spirv.size() * 4 == built.size()
                  && !memcmp(r.spirv.data(), built.data(), built.size());
        if (!equal)
            check(false, name + " compiles to the build's SPIR-V" + (r.ok ? "" : " (" + r.log + ")"));
        same += equal;
    }
    check(same == (int)stages.size(),
        std::to_string(same) + " of " + std::to_string(stages.size()) + " stages byte for byte as the build's");
}

/* The files a compile read: the stage and its includes, recursively
 * (native.frag reads material.glsl through native_frag.glsl). */
static bool reads(const shader_compiler::Result& r, const char* name)
{
    for (const std::string& f : r.files)
        if (base_name(f) == name)
            return true;
    return false;
}
static void reports_its_files(const std::string& shaders)
{
    shader_compiler::Result scaled = shader_compiler::compile(shaders + "/scaled.frag");
    check(scaled.ok && reads(scaled, "scaled.frag") && reads(scaled, "material_pack.glsl"),
        "scaled.frag read itself and material_pack.glsl (" + std::to_string(scaled.files.size()) + " files)");
    shader_compiler::Result native = shader_compiler::compile(shaders + "/native.frag");
    check(native.ok && reads(native, "native_frag.glsl") && reads(native, "material.glsl"),
        "native.frag read native_frag.glsl and, through it, material.glsl");
}

/* A broken stage: no SPIR-V, and the log names the file and line. */
static void fails_with_its_line(const std::string& shaders, const std::string& scratch)
{
    std::string text;
    check(read_file(shaders + "/fullscreen.vert", text), "fullscreen.vert read");
    /* Line 3 is the error (after the #version line and one more). */
    size_t first = text.find('\n'), second = text.find('\n', first + 1);
    std::string broken = text.substr(0, second + 1) + "#error broken\n" + text.substr(second + 1);
    std::string path = scratch + "/fullscreen.vert";
    std::ofstream(path, std::ios::binary) << broken;
    shader_compiler::Result r = shader_compiler::compile(path);
    check(!r.ok && r.spirv.empty(), "the broken copy fails");
    check(r.log.find(path + ":3:") != std::string::npos, "its log names the file and line 3: " + r.log);
    shader_compiler::Result missing = shader_compiler::compile(scratch + "/missing.frag");
    check(!missing.ok && !missing.log.empty(), "a missing file fails: " + missing.log);
}

/* The named lookup every vk_shader goes through (vk_shader_lookup.c): an
 * override set for a name is what its module is made from, until cleared. */
static void lookup_takes_overrides()
{
    static const uint32_t embedded[] = { 0x07230203, 1, 2 }, other[] = { 0x07230203, 9 };
    size_t bytes = sizeof embedded;
    check(vk_shader_code("fullscreen_vert", embedded, &bytes) == embedded && bytes == sizeof embedded,
        "no override: the embedded code");
    vk_shader_override("fullscreen_vert", other, sizeof other);
    const uint32_t* code = vk_shader_code("fullscreen_vert", embedded, &bytes);
    check(code != other && bytes == sizeof other && !memcmp(code, other, sizeof other),
        "an override (a copy) for fullscreen_vert");
    bytes = sizeof embedded;
    check(vk_shader_code("scaled_frag", embedded, &bytes) == embedded, "other names keep theirs");
    check(vk_shader_override_name(0) && !strcmp(vk_shader_override_name(0), "fullscreen_vert")
            && !vk_shader_override_name(1), "the overridden names listed");
    vk_shader_override("fullscreen_vert", NULL, 0);
    bytes = sizeof embedded;
    check(vk_shader_code("fullscreen_vert", embedded, &bytes) == embedded && !vk_shader_override_name(0),
        "cleared: the embedded code again");
    vk_shader_override("a_frag", other, sizeof other);
    vk_shader_override("b_frag", other, sizeof other);
    vk_shader_overrides_clear();
    check(!vk_shader_override_name(0), "all cleared");
    size_t built = 0;
    const uint32_t* builtin = vk_shader_builtin("scaled_frag", &built);
    check(builtin && built > 1000 && builtin[0] == 0x07230203 && !vk_shader_builtin("no_such_frag", &built),
        "the built-in SPIR-V by name");
}

/* The layout contract (reflect, contract_mismatch): every built-in stage
 * keeps its own; an added binding, a binding of another type, larger push
 * constants or an output with no attachment break it. */
static void keeps_the_contract(const std::string& shaders, const std::string& scratch)
{
    int own = 0, total = 0;
    if (DIR* dir = opendir(shaders.c_str())) {
        while (dirent* e = readdir(dir)) {
            std::string name = e->d_name;
            size_t dot = name.rfind('.');
            std::string ext = dot == std::string::npos ? "" : name.substr(dot + 1);
            if (ext != "vert" && ext != "geom" && ext != "frag" && ext != "comp")
                continue;
            shader_compiler::Result r = shader_compiler::compile(shaders + "/" + name);
            shader_compiler::Interface i = shader_compiler::reflect(r.spirv.data(), r.spirv.size());
            ++total;
            own += r.ok && i.valid && shader_compiler::contract_mismatch(i, i).empty();
        }
        closedir(dir);
    }
    check(total > 40 && own == total, std::to_string(own) + " of " + std::to_string(total) + " stages read and keep their own contract");
    std::string text;
    read_file(shaders + "/scaled.frag", text);
    shader_compiler::Result base = shader_compiler::compile(shaders + "/scaled.frag");
    shader_compiler::Interface contract = shader_compiler::reflect(base.spirv.data(), base.spirv.size());
    check(contract.outputs == std::vector<int> { 0 } && !contract.bindings.empty() && contract.bindings[0].first == 0
            && contract.bindings[0].second == 5, "scaled.frag: one output, binding 0 a uniform buffer");
    auto variant = [&](const std::string& name, const std::string& from, const std::string& to) {
        std::string changed = text;
        size_t at = changed.find(from);
        if (at != std::string::npos)
            changed.replace(at, from.size(), to);
        std::string path = shaders + "/" + name; /* beside its includes (a copy of the folder) */
        std::ofstream(path, std::ios::binary) << changed;
        shader_compiler::Result r = shader_compiler::compile(path);
        return r.ok ? shader_compiler::contract_mismatch(contract,
                          shader_compiler::reflect(r.spirv.data(), r.spirv.size()))
                    : "compile failed: " + r.log;
    };
    std::string why = variant("extra.frag", "void main() {\n",
        "layout(binding = 30) uniform sampler2D extra_tex;\nvoid main() {\n    color = texture(extra_tex, uv);\n    return;\n");
    check(why.find("binding 30") != std::string::npos, "an added binding breaks it: " + why);
    why = variant("retyped.frag", "void main() {\n",
        "layout(binding = 23, rgba8) uniform readonly image2D retyped;\nvoid main() {\n"
        "    color = imageLoad(retyped, ivec2(0));\n    return;\n");
    check(why.find("binding 23") != std::string::npos, "a binding of another type breaks it: " + why);
    why = variant("output.frag", "layout(location = 0) out vec4 color;",
        "layout(location = 0) out vec4 color;\nlayout(location = 1) out vec4 second;");
    check(why.find("output location 1") != std::string::npos, "an output with no attachment breaks it: " + why);
    why = variant("same.frag", "void main() {\n", "void main() {\n    color = vec4(1.0, 0.0, 1.0, 1.0);\n    return;\n");
    check(why.empty(), "a stage using less keeps it");
    std::string fxaa_text;
    read_file(shaders + "/fxaa.frag", fxaa_text);
    shader_compiler::Result fxaa = shader_compiler::compile(shaders + "/fxaa.frag");
    shader_compiler::Interface fxaa_contract = shader_compiler::reflect(fxaa.spirv.data(), fxaa.spirv.size());
    size_t brace = fxaa_text.find("{", fxaa_text.find("push_constant"));
    std::string bigger = fxaa_text.substr(0, brace + 1) + "\n    vec4 extra_push[8];" + fxaa_text.substr(brace + 1);
    std::ofstream(scratch + "/fxaa.frag", std::ios::binary) << bigger;
    shader_compiler::Result big = shader_compiler::compile(scratch + "/fxaa.frag");
    why = shader_compiler::contract_mismatch(fxaa_contract, shader_compiler::reflect(big.spirv.data(), big.spirv.size()));
    check(fxaa_contract.push_bytes > 0 && why.find("push constants") != std::string::npos,
        "larger push constants break it (fxaa.frag " + std::to_string(fxaa_contract.push_bytes) + " bytes): " + why);
}

int main(int argc, char** argv)
{
    if (argc != 4) {
        fprintf(stderr, "usage: %s <shader dir> <spv dir> <scratch dir>\n", argv[0]);
        return 2;
    }
    check(shader_compiler::init(), "glslang starts");
    matches_the_build(argv[1], argv[2]);
    reports_its_files(argv[1]);
    fails_with_its_line(argv[1], argv[3]);
    lookup_takes_overrides();
    keeps_the_contract(argv[1], argv[3]);
    shader_compiler::shutdown();
    printf("%s (%d failed)\n", failures ? "FAIL" : "PASS", failures);
    return failures ? 1 : 0;
}
