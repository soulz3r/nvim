import unittest
from pathlib import Path

from lua_indentation import indentation_errors


class LuaIndentationTests(unittest.TestCase):
    def test_tabs_are_accepted(self):
        self.assertEqual(
            indentation_errors(["local value = 1", "\tlocal nested = 2"], "example.lua"),
            [],
        )

    def test_leading_spaces_are_rejected(self):
        errors = indentation_errors(["    local value = 1"], "example.lua")
        self.assertEqual(len(errors), 1)
        self.assertIn("example.lua:1", errors[0])

    def test_mixed_leading_indentation_is_rejected(self):
        errors = indentation_errors(["\t  local value = 1"], "example.lua")
        self.assertEqual(len(errors), 1)

    def test_keymap_ex_command_body_is_the_only_indentation_exception(self):
        lines = [
            "vim.cmd([[",
            "  :amenu 10.100 mousemenu.Goto\\ Definition <cmd>lua vim.lsp.buf.definition()<CR>",
            "  :amenu 10.110 mousemenu.References <cmd>lua vim.lsp.buf.references()<CR>",
            "]])",
            "\tlocal valid = true",
        ]
        self.assertEqual(indentation_errors(lines, Path("lua/soul/core/keymaps.lua")), [])

    def test_indentation_after_ex_command_is_still_checked(self):
        lines = ["vim.cmd([[", "  :amenu 10.100 mousemenu.Goto", "]])", "    local invalid = true"]
        errors = indentation_errors(lines, Path("lua/soul/core/keymaps.lua"))
        self.assertEqual(len(errors), 1)
        self.assertIn("keymaps.lua:4", errors[0])

    def test_other_files_do_not_receive_the_ex_command_exception(self):
        lines = ["vim.cmd([[", "  this is not an exempt file", "]])"]
        errors = indentation_errors(lines, Path("lua/soul/other.lua"))
        self.assertEqual(len(errors), 1)

    def test_unterminated_ex_command_is_rejected(self):
        errors = indentation_errors(
            ["vim.cmd([[", "  :amenu 10.100 mousemenu.Goto"],
            Path("lua/soul/core/keymaps.lua"),
        )
        self.assertEqual(len(errors), 1)
        self.assertIn("unterminated", errors[0])


if __name__ == "__main__":
    unittest.main()
