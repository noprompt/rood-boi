# Shader Hot Reload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Saving a shader under `pc/shaders/vulkan` shows in the running game (Vulkan) within about a second, with no rebuild or restart; a broken shader shows its error and the game keeps the last good one.

**Architecture:** glslang (vendored) is linked into the game as a library. A reload service polls the shader sources, compiles the changed stages (and the stages that include a changed `.glsl`) on a background thread, and on success hands the new SPIR-V to a named lookup that every `vk_shader` call goes through, then restarts the renderer in place at a safe point. The restart is engine reload's renderer sequence (`engine_reload.c`: overlay, NRD, Vulkan down, then up, `pc_hw_resync`) without the library swap; the persistent pipeline cache keeps it fast. Per-pipeline swapping is a later optimisation, not this plan.

**Tech Stack:** C/C++ (pc/src), glslang C++ API, Vulkan, SDL3 threads, Python smoke tests (pc/tests).

**Spec:** `pc/docs/plans/2026-10-27-materials-and-inspection-design.md`, part 1 ("Shader hot reload") and "Calls made in review" (shader compilation ships).

## Global Constraints

- glslang is linked into the game on every 64-bit platform (Linux, Windows via `pc/tools/windows_dist.py`); the embedded SPIR-V (`vk_shaders.h`) stays the default and the fallback.
- Compiled SPIR-V is cached under the build folder, never committed.
- Same compile options as `pc/tools/vk_shaders.py`: `-V --target-env vulkan1.3`, includes `pc/shaders/vulkan` and `pc/third_party/smaa`.
- A failed compile never replaces a working shader and never blacks out the game.
- Look/feel and behaviour parameters are settings (settings.cfg, dev panel, RPC), never constants.
- With no shader edited, frames are byte-identical to today's.
- Vulkan only; the GL renderer is untouched.
- Lua access comes with the `rood.imgui` / dev-RPC bridge project, not here (the RPC added here is what it will forward).
- Workers run targeted suites only (`pc/tests/run.py <suite names>`); no full verify.

## Review Focus

- An edit to an included `.glsl` (e.g. `material.glsl`) reloads every stage that includes it, directly or through another include.
- An editor saving in several writes (or a save caught mid-write): the service waits until the file's mtime and size are unchanged for one poll before compiling.
- Several saves in quick succession: compiles coalesce; the newest sources win and no stale result is applied after a newer one.
- No shader sources on disk (a shipped build, `ROOD_SHADERS` pointing nowhere): the service stays off silently and nothing changes.
- Repeated reloads leak nothing: the Vulkan object tracker (`vk_core.c` track_*) reports no leaked objects after 5 reloads.

---

### Task 1: glslang as a library, and an in-process compiler

**Files:**
- Modify: `pc/tools/vk_shaders.py` (add the static library build beside the standalone one)
- Modify: `pc/tools/build_boot.py:580-600` (link it in the 64-bit and Windows builds), `pc/tools/windows_dist.py` (glslang's licence files)
- Create: `pc/src/shader_compiler.h`, `pc/src/shader_compiler.cpp`
- Create: `pc/tests/shader_compiler_probe.cpp`, registered in `pc/tests/run.py` as suite `shader_compiler` and in `pc/tests/affected.toml` (paths `pc/src/shader_compiler.*`, `pc/shaders/vulkan/**`, `pc/tools/vk_shaders.py`)

**Interfaces:**
- Produces:
  - `vk_shaders.glslang_libraries(key) -> list[pathlib.Path]` (Python; the static libs from the shared cache entry `glslang-lib-<key>`, built with the same `OPTIONS`; include dir is the vendored source)
  - `namespace shader_compiler { struct Result { bool ok; std::vector<uint32_t> spirv; std::string log; std::vector<std::string> files; }; Result compile(const std::string& path); }` — `path` is a stage file (`<name>.<vert|geom|frag|comp>`); `files` lists every file read (the stage and each include, recursively), for dependency tracking; `log` has `file:line: message` lines on failure.
  - `bool shader_compiler::init()` / `void shader_compiler::shutdown()` (glslang process init, once).

- [ ] **Step 1: Write the failing probe.** `shader_compiler_probe` compiles every stage file in `pc/shaders/vulkan` and asserts each result equals the build's SPIR-V byte for byte (`pc/build/boot64/vk_spv/<stem>_<stage>.spv`, written by `vk_shaders.py`); asserts `files` of `scaled.frag` contains `material.glsl`; asserts a temp copy of `fullscreen.vert` with `#error broken` on line 3 gives `ok == false` and a `log` containing `:3:`.
- [ ] **Step 2: Run it and see it fail** — `python3 pc/tests/run.py shader_compiler`: FAIL (no `shader_compiler.h`).
- [ ] **Step 3: Build and link the glslang libraries; implement `shader_compiler`** with glslang's C++ API (`TShader`, `TProgram`, `GlslangToSpv`, the default resource limits) and an includer that resolves against the two include dirs and records each file it opens. If the byte-for-byte check cannot hold (e.g. the standalone adds debug info differently), match the standalone's options until it does; do not relax the check.
- [ ] **Step 4: Run it and see it pass** — same command: PASS. Also `python3 pc/tools/build_boot.py --arch 64` and the Windows build link.
- [ ] **Step 5: Commit.**

### Task 2: Every shader module through a named lookup

**Files:**
- Modify: `pc/src/vk_core.h:277`, `pc/src/vk_core.c:1453`
- Modify: every `vk_shader(vk_spv_X, vk_spv_X_size)` call site (30, in `vk_core.c`, `vk_present.c`, `vk_hw.c`, `vk_render.inc`, `vk_rt.inc`, `post_vk.inc`, `vk_shadows.c`, `vk_nrd.cpp`, `ui_upscale.c`)

**Interfaces:**
- Produces:
  - `#define VK_SHADER(name) vk_shader_named(#name, vk_spv_##name, vk_spv_##name##_size)` — `name` is the generated stem, e.g. `VK_SHADER(scaled_frag)`.
  - `VkShaderModule vk_shader_named(const char* name, const uint32_t* code, size_t bytes)` — uses the override for `name` if one is set, else `code`.
  - `void vk_shader_override(const char* name, const uint32_t* code, size_t bytes)` (copies; `code == NULL` clears) and `void vk_shader_overrides_clear(void)`.

- [ ] **Step 1: Write the failing check** — in `shader_compiler_probe`, a case that sets an override for `fullscreen_vert` and asserts `vk_shader_named` picks it (test the lookup function only; it needs no device if the lookup is split out as `const uint32_t* vk_shader_code(const char* name, const uint32_t* code, size_t* bytes)`, which `vk_shader_named` calls).
- [ ] **Step 2: Run it and see it fail.**
- [ ] **Step 3: Implement the lookup and replace all 30 call sites with `VK_SHADER(...)`.** Every call must go through it (grep: no `vk_shader(vk_spv_` left).
- [ ] **Step 4: Run** `python3 pc/tests/run.py shader_compiler material_smoke engine_reload_smoke` (Vulkan): PASS, frames unchanged.
- [ ] **Step 5: Commit.**

### Task 3: The reload service, the in-place renderer restart, RPC and overlay

**Files:**
- Create: `pc/src/shader_reload.cpp`, `pc/src/shader_reload.h`
- Modify: `pc/src/engine_reload.c` (factor the renderer down/up into `pc_renderer_restart`)
- Modify: `pc/src/dev_rpc.c` (method `shaders`), `pc/src/dev_overlay.cpp` (error banner), the settings table (two settings below)
- Create: `pc/tests/shader_reload_smoke.py`, registered in `run.py` (Vulkan) and `affected.toml`
- Modify: `pc/docs/Vulkan_Renderer.md` (a "Hot reload" section)

**Interfaces:**
- Consumes: `shader_compiler::compile`, `vk_shader_override`.
- Produces:
  - `void pc_shader_reload_poll(void)` — called once per presented frame; does the polling and, when a compile finished, the apply.
  - `int pc_renderer_restart(void)` — overlay, NRD and Vulkan down, then up and `pc_hw_resync()`, keeping the window, settings, Lua and RPC; 0 on success. `rood_engine_unload`/`rood_engine_resume` call into the same pieces.
  - Settings: `shader_reload` (0/1; default 1; the service is off anyway when the source dir has no stage files) and `shader_reload_poll_ms` (default 500, 100..5000).
  - Source dir: `$ROOD_SHADERS`, else `pc/shaders/vulkan`.
  - RPC `shaders`: `status` → `{on, dir, generation, pending, last_ms, errors: [{file, line, message}], overridden: [names]}`; `reload` (compile everything now, apply if clean); `reset` (drop overrides, back to embedded, restart).
  - Overlay: while `errors` is non-empty, a banner with the first error (`file:line: message`) and the count.

- [ ] **Step 1: Write the failing smoke test** `shader_reload_smoke.py` (headless Vulkan, a copy of `pc/shaders/vulkan` in a temp dir as `ROOD_SHADERS`, mirror `material_review_smoke.py`'s start-up):
  - capture a frame; edit the copy's `scaled.frag` so its output is a constant magenta; within 3 s `generation` increases and the frame's centre pixel is magenta;
  - edit `material.glsl` (an include) with a harmless change to an existing constant's comment and assert `generation` increases and `scaled_frag` is in `overridden`;
  - break `scaled.frag` (a syntax error on a known line): `errors[0]` names that file and line, `generation` does not change, the frame is still magenta (last good kept);
  - restore the original file: errors clear, the frame matches the first capture byte for byte;
  - write a stage in two halves 100 ms apart: exactly one apply, of the complete file;
  - 5 reloads in a row, then quit: the Vulkan tracker reports no leaked objects;
  - `ROOD_SHADERS` pointing at an empty dir: `on` false, nothing reloads.
- [ ] **Step 2: Run it and see it fail** — `python3 pc/tests/run.py shader_reload_smoke`: FAIL (no RPC `shaders`).
- [ ] **Step 3: Implement.** Polling: per stage file and per recorded include, mtime and size; a change is acted on only once unchanged for one poll. Compile on an SDL thread; one job at a time, a newer change cancels the result of an older job. Dependencies: the `files` of each stage's last compile (first run: compile nothing, just record by compiling lazily on first change of anything; or compile all once in the background at start — implementer's choice, but the include test must pass). Apply at `pc_shader_reload_poll` (between frames): set the overrides, `pc_renderer_restart()`, increase `generation`, record `last_ms`.
- [ ] **Step 4: Run** `python3 pc/tests/run.py shader_reload_smoke shader_compiler engine_reload_smoke material_smoke`: PASS.
- [ ] **Step 5: Document** in `Vulkan_Renderer.md` (what reloads, the settings, the RPC, the error banner, the restart cost measured).
- [ ] **Step 6: Commit.**
