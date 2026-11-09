"""Audit retained raw editor/setup/suite logs; runner summaries do not expose every setup diagnostic."""
import hashlib
import json
from pathlib import Path
import re


def inspect(path):
    raw = path.read_bytes()
    text = re.sub(r"\x1b\[[0-9;]*m", "", raw.decode("utf-8", errors="replace"))
    return {"bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest(), "engine_errors": [line for line in text.splitlines() if re.match(r"^\s*ERROR:", line)], "script_errors": [line for line in text.splitlines() if re.search(r"SCRIPT ERROR|Parse Error|Could not find type|Failed to load script", line)], "warning_count": sum("WARNING:" in line for line in text.splitlines()), "suite_results": re.findall(r"^(?:HINT PLAYER RESULT:.*|[0-9]+/[0-9]+ suites passed)$", text, re.M)}


def main():
    root = Path(__file__).resolve().parent
    results = []
    for folder in [root / "final", root / "sidecar_restore"]:
        if not folder.exists():
            continue
        for path in sorted(folder.rglob("*")):
            if path.is_file() and path.suffix in [".txt", ".log"]:
                results.append({"file": path.relative_to(root).as_posix(), **inspect(path)})
    report = {"scope": "Full retained setup/suite/editor logs, excluding intentional preliminary interruption and collector console summaries.", "logs": results, "engine_error_count": sum(len(row["engine_errors"]) for row in results), "script_error_count": sum(len(row["script_errors"]) for row in results)}
    (root / "setup_log_audit.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps({key: report[key] for key in ["engine_error_count", "script_error_count"]}))


if __name__ == "__main__":
    main()
