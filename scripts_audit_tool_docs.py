from pathlib import Path
import re

root = Path(".")
files = sorted(
    p for p in root.rglob("*.md") if p.parts and re.match(r"^\d\d\s-\s", p.parts[0])
)

results = []

for p in files:
    text = p.read_text(encoding="utf-8", errors="ignore")
    lower = text.lower()

    has_install_section = bool(
        re.search(r"^##\s+installation\b", text, flags=re.I | re.M)
    )
    has_config_section = bool(
        re.search(r"^##\s+configuration\b", text, flags=re.I | re.M)
    )
    has_usage_section = bool(
        re.search(r"^##\s+(start\s*/\s*usage|usage|start)\b", text, flags=re.I | re.M)
    )

    shell_blocks = re.findall(r"```shell([\s\S]*?)```", text, flags=re.I)
    shell_text = "\n".join(shell_blocks).lower()

    has_install_cmd = bool(
        re.search(
            r"\b(brew|pip|pip3|npm|pnpm|cargo|gem|go|sdk|curl)\s+install\b", shell_text
        )
    )
    has_config_signal = has_config_section or bool(
        re.search(
            r"\b(config|configure|setup|init|\.zshrc|preferences|settings)\b", lower
        )
    )
    has_start_signal = has_usage_section or bool(
        re.search(
            r"\b(start|run|serve|launch|open the app|first-run|first run|usage)\b",
            lower,
        )
    )

    missing = []
    if not (has_install_section or has_install_cmd or shell_blocks):
        missing.append("installation")
    if not has_config_signal:
        missing.append("basic configuration")
    if not has_start_signal:
        missing.append("start/basic usage")

    weak_usage = False
    if shell_blocks and not has_usage_section:
        has_run_cmd = bool(
            re.search(
                r"\b(start|run|serve|launch|open|k9s|kubectl|docker run|terraform (plan|apply)|jupyter|ollama run|python\s+|node\s+)\b",
                shell_text,
            )
        )
        if has_install_cmd and not has_run_cmd:
            weak_usage = True

    if missing or weak_usage:
        results.append((str(p), missing, weak_usage))

print(f"TOTAL_FILES={len(files)}")
print(f"FILES_WITH_GAPS={len(results)}")
for file_path, missing, weak_usage in results:
    tags = []
    if missing:
        tags.append("missing: " + ", ".join(missing))
    if weak_usage:
        tags.append("weak_usage")
    print(f"{file_path} :: " + " | ".join(tags))
