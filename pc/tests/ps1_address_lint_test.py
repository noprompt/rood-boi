#!/usr/bin/env python3
"""ps1_address_lint: comments do not count, code does, and a rise fails."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "tools"))
import ps1_address_lint as lint  # noqa: E402


class Ps1AddressLintTest(unittest.TestCase):
    def test_comments_are_blanked_and_strings_kept(self):
        code = lint.strip_comments('int a; /* 0x80010000\n0x1F800000 */ int b; // D_80100000\nchar* s = "// x";\n')
        self.assertNotIn("0x80010000", code)
        self.assertNotIn("D_80100000", code)
        self.assertIn('"// x"', code)
        self.assertEqual(code.count("\n"), 3)

    def test_rules_match_what_they_name(self):
        for rule, text in [("ps1_address", "p = 0x80010000;"), ("scratchpad", "p = 0x1F800004;"),
                           ("unnamed_symbol", "D_800F4910 = vs_battle_collectEnvironmentActionTargets();"), ("guest_pointer_field", "psx_ptr(int) p;"),
                           ("guest_pointer_access", "psx_get(p->next)"), ("address_as_integer", "psx_to_int(u_int, p)"),
                           ("zig_raw_memory", "psx.byteAt(u32, p, 4)")]:
            self.assertTrue(lint.RULES[rule].search(text), rule)
        self.assertFalse(lint.RULES["ps1_address"].search("x = 0x8001;"))

    def test_vram_readback_names_the_reads_into_the_games_array(self):
        rule = lint.RULES["vram_readback"]
        for name in ("pc_hwc_fence_sync", "pc_rq_readback_apply", "pc_hw_capture_read", "pc_hw_sync_texture", "pc_hw_stale_copy", "rvram_apply"):
            self.assertTrue(rule.search(name + "(x);"), name)
        for name in ("pc_hw_sample_texture", "pc_hwc_texture_sample", "own_from_target", "pc_frame_read", "pc_hwc_capture_picture"):  # (GPU-side, a caller of the read, or no write into the array)
            self.assertFalse(rule.search(name + "(x);"), name)

    def test_game_code_names_no_renderer_symbol(self):
        rule = lint.RULES["renderer_symbol"]
        for text in ('psx.weak(Anchor, "pc_hw_anchor_packets")', "extern int pc_hw_opacity_on(void);", "render_mesh_posed(m);", "pc_vk_hw_capture(0, 1, 2, 3, 4);"):
            self.assertTrue(rule.search(text), text)
        for text in ("vs_render_drawGimTiles(p);", "render_text_immediate(x);", "pc_frame_sprite(1, 2);"):  # (the game's own names)
            self.assertFalse(rule.search(text), text)
        self.assertEqual(lint.ONLY_UNDER["renderer_symbol"], ("game/", "pc/src/game/"))  # (the renderer's own files name them freely)

    def test_only_a_rise_fails(self):
        rose, fell = lint.compare({"a": 5, "b": 2, "c": 3}, {"a": 4, "b": 3, "c": 3})
        self.assertEqual(rose, {"a": (4, 5)})
        self.assertEqual(fell, {"b": (3, 2)})


if __name__ == "__main__":
    unittest.main()
