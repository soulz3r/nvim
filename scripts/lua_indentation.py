from pathlib import Path
import sys


KEYMAPS_PATH = Path("lua/soul/core/keymaps.lua")


def indentation_errors(lines, relative_path):
    """Return indentation errors, excluding only the literal Ex menu body."""
    errors = []
    in_ex_command = False
    allow_ex_command = Path(relative_path) == KEYMAPS_PATH

    for line_number, line in enumerate(lines, 1):
        if in_ex_command:
            if "]])" in line:
                in_ex_command = False
            continue

        prefix = line[: len(line) - len(line.lstrip(" \t"))]
        if " " in prefix:
            errors.append(
                f"{relative_path}:{line_number}: Lua indentation must use tabs, not spaces."
            )

        if allow_ex_command and "vim.cmd([[" in line:
            in_ex_command = True

    if in_ex_command:
        errors.append(f"{relative_path}: unterminated vim.cmd([[ ... ]]) literal block.")

    return errors


def check_repository(root):
    root = Path(root)
    errors = []

    for path in root.rglob("*.lua"):
        if not path.is_file() or ".git" in path.parts:
            continue

        relative_path = path.relative_to(root)
        try:
            content = path.read_bytes()
            if b"\r" in content:
                errors.append(f"{relative_path}: Lua files must use LF line endings.")
                continue

            lines = content.decode("utf-8").splitlines()
        except (OSError, UnicodeDecodeError) as error:
            errors.append(f"{relative_path}: could not read Lua source: {error}")
            continue

        errors.extend(indentation_errors(lines, relative_path))

    return errors


if __name__ == "__main__":
    repository_root = Path(__file__).resolve().parents[1]
    problems = check_repository(repository_root)

    if problems:
        print("\n".join(problems), file=sys.stderr)
        sys.exit(1)

    print("Lua indentation and line-ending checks passed.")
