return {
  id = "rood.material_review",
  name = "Material review (Lua)",
  version = "1.0.0",
  api_version = 1,
  description = "Window > Material review written in Lua on RPC material_review: replaces the C++ window while "
    .. "it is on. Off by default (the C++ window is the fallback until this one is the default).",
  author = "rood-boi",
  default_enabled = false,
  capabilities = { "dev.tools" },
}
