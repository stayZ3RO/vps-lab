"""Keep project phase claims in the canonical Markdown file."""
import re
import subprocess
import sys
from pathlib import Path

ALLOWED = {
    "phase-state.md",
    "README.md",
    "CHANGELOG.md",
    "docs/README.md",
}


CLAIM = re.compile(
    r"current_phase|badge/next-|\bcurrent phase\b|^\s*phase:\s*\**phase\s+\d"
    r"|\b(?:now in|ready for)(?:\s+|:\s*)(?:\**phase\s+\d)|\b(?:now in|project is (?:now )?ready for):\s*$",
    re.IGNORECASE,
)
FENCE = re.compile(r"^ {0,3}(\x60{3,}|~{3,})(.*)$")


def claims(path, text):
    if path in ALLOWED:
        return []
    lines = []
    fence = ""
    fenced_claims = []
    for n, line in enumerate(text.splitlines(), 1):
        marker = FENCE.match(line)
        if fence:
            if marker and marker[1].startswith(fence) and not marker[2].strip():
                fence = ""
                fenced_claims.clear()
            elif CLAIM.search(line):
                fenced_claims.append(n)
        elif marker:
            fence = marker[1]
        elif CLAIM.search(line):
            lines.append(n)
    # An unfinished example must not hide the rest of the document.
    return lines + fenced_claims


def self_test():
    samples = ["![Next](/badge/next-example)", "## Current Phase", "current_phase-x",
               "The project is now in:", "Ready for Phase 4", "Ready for: Phase 4", "The project is now in: Phase 4", "Phase: **Phase 3**"]
    for sample in samples:
        assert claims("other.md", sample) == [1], sample
        assert claims("phase-state.md", sample) == []
    for fence in ("\x60\x60\x60", "~~~~"):
        assert claims("other.md", f"{fence}md\nReady for Phase 4\n{fence}\nNow in Phase 5") == [4]
    assert claims("other.md", "~~~\nNow in Phase 4") == [2]
    assert claims("other.md", "The logs are ready for a log stack in Phase 5.") == []
    print("State claim self-test passed.")


def main():
    if sys.argv[1:] == ["--self-test"]:
        self_test()
        return 0
    if sys.argv[1:]:
        sys.exit("Usage: python3 scripts/check-state-claims.py [--self-test]")
    paths = subprocess.check_output(["git", "ls-files", "-z", "--", "*.md"], text=True)
    failed = False
    for path in filter(None, paths.split("\0")):
        for line in claims(path, Path(path).read_text(encoding="utf-8")):
            print(f"{path}:{line}: move the phase claim to phase-state.md")
            failed = True
    if failed:
        return 1
    print("State claims only in allowed files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
