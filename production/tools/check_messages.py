#!/usr/bin/env python3
"""Validate campaign message packs against narrative bridge rules and story canon."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple

VALID_THREADS: Set[str] = {"crew", "commander", "earth", "academy", "archive"}
VALID_UNLOCK_KINDS: Set[str] = {"scene_enter", "scene_exit", "mission_done", "job_done", "found"}
BANGLA_RE = re.compile(r"[\u0980-\u09FF]")
FORBIDDEN_PRE_REVEAL_NAMES = (
    re.compile(r"\bNoor\b", re.IGNORECASE),
    re.compile(r"\bRahman\b", re.IGNORECASE),
)
SCENE_ID_RE = re.compile(r"^EX-CH(\d{2})-S(\d{2})$")
JOIN_ROW_RE = re.compile(r"^\|\s*(?:\*\*)?`?(CH\d{2}[^|*`]+?)`?(?:\*\*)?\s*\|")


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def parse_doc24_joins(doc_path: Path) -> List[str]:
    text = doc_path.read_text(encoding="utf-8")
    in_section = False
    joins: List[str] = []
    for line in text.splitlines():
        if line.startswith("### 2.9"):
            in_section = True
            continue
        if in_section and (line.startswith("### ") or line.startswith("## ") or line.startswith("**Montage beat sheets")):
            break
        if not in_section:
            continue
        match = JOIN_ROW_RE.match(line.strip())
        if match:
            join_id = match.group(1).strip()
            if join_id.startswith("CH"):
                joins.append(join_id)
    return joins


def join_chapter_number(join_id: str) -> int:
    match = re.match(r"^CH(\d{2})\b", join_id)
    if not match:
        return 0
    return int(match.group(1))


def load_story_ids(story_path: Path) -> Tuple[Set[str], Set[str], Dict[str, Tuple[int, int]]]:
    data = json.loads(story_path.read_text(encoding="utf-8"))
    scene_ids: Set[str] = set()
    mission_ids: Set[str] = set()
    mission_last_scene: Dict[str, Tuple[int, int]] = {}

    for chapter in data.get("chapters", []):
        ch_num = int(chapter.get("id", chapter.get("number", 0)))
        missions = chapter.get("missions", [])
        scenes = chapter.get("scenes", [])
        for idx, mission in enumerate(missions):
            mid = str(mission.get("id", "")).strip()
            if mid:
                mission_ids.add(mid)
                mission_last_scene[mid] = (ch_num, min(12, (idx + 1) * 3))
        for scene in scenes:
            sid = str(scene.get("id", "")).strip()
            if sid:
                scene_ids.add(sid)

    for scene in data.get("scenes", []):
        sid = str(scene.get("id", "")).strip()
        if sid:
            scene_ids.add(sid)

    return scene_ids, mission_ids, mission_last_scene


def unlock_position(
    chapter_num: int,
    unlock_on: str,
    unlock_id: str,
    join_str: str,
    mission_last_scene: Dict[str, Tuple[int, int]],
) -> Tuple[int, int]:
    """Return (chapter, scene_number) where this message can first appear."""
    sm = SCENE_ID_RE.match(unlock_id)
    if sm:
        return int(sm.group(1)), int(sm.group(2))
    if unlock_on == "mission_done" and unlock_id in mission_last_scene:
        return mission_last_scene[unlock_id]
    jm = re.search(r"CH(\d{2})\s+S(\d{2})", join_str)
    if jm:
        return int(jm.group(1)), int(jm.group(2))
    return chapter_num, 1


def validate_messages(
    root: Path,
    require_all_chapters: bool = False,
) -> List[str]:
    errors: List[str] = []
    doc24_path = root / "game-design" / "24_NARRATIVE_REVISION.md"
    story_path = root / "full-game-story" / "story-data.json"
    messages_dir = root / "game" / "resources" / "campaign" / "content" / "messages"

    if not doc24_path.is_file():
        return [f"Missing narrative revision doc: {doc24_path}"]
    if not story_path.is_file():
        return [f"Missing story data file: {story_path}"]
    if not messages_dir.is_dir():
        return [f"Missing messages directory: {messages_dir}"]

    expected_joins = parse_doc24_joins(doc24_path)
    if not expected_joins:
        errors.append("Failed to parse any bridge joins from game-design/24_NARRATIVE_REVISION.md §2.9")

    valid_scenes, valid_missions, mission_last_scene = load_story_ids(story_path)

    chapter_files = sorted(messages_dir.glob("ch*.json"))
    if not chapter_files:
        errors.append(f"No ch*.json files found in {messages_dir}")
        return errors

    seen_ids: Dict[str, str] = {}
    join_counts: Dict[str, int] = {j: 0 for j in expected_joins}
    present_chapters: Set[int] = set()

    for file_path in chapter_files:
        try:
            payload = json.loads(file_path.read_text(encoding="utf-8"))
        except Exception as exc:  # noqa: BLE001
            errors.append(f"{file_path.name}: invalid JSON ({exc})")
            continue

        if not isinstance(payload, dict):
            errors.append(f"{file_path.name}: root must be a JSON object")
            continue

        chapter_num = payload.get("chapter")
        if not isinstance(chapter_num, int) or chapter_num < 0 or chapter_num > 8:
            errors.append(f"{file_path.name}: 'chapter' must be an integer in 0..8")
            continue

        if chapter_num > 0:
            present_chapters.add(chapter_num)

        messages = payload.get("messages")
        if not isinstance(messages, list) or not messages:
            errors.append(f"{file_path.name}: 'messages' must be a non-empty list")
            continue

        for idx, msg in enumerate(messages):
            ctx = f"{file_path.name}[{idx}]"
            if not isinstance(msg, dict):
                errors.append(f"{ctx}: message entry must be an object")
                continue

            msg_id = str(msg.get("id", "")).strip()
            if not msg_id:
                errors.append(f"{ctx}: missing 'id'")
            else:
                ctx = f"{file_path.name}:{msg_id}"
                if msg_id in seen_ids:
                    errors.append(f"{ctx}: duplicate message id '{msg_id}' (already in {seen_ids[msg_id]})")
                else:
                    seen_ids[msg_id] = file_path.name

            thread = str(msg.get("thread", "")).strip()
            if thread not in VALID_THREADS:
                errors.append(f"{ctx}: invalid thread '{thread}' (expected one of {sorted(VALID_THREADS)})")

            sender = str(msg.get("sender", "")).strip()
            if not sender:
                errors.append(f"{ctx}: missing 'sender'")

            story_time = str(msg.get("story_time", "")).strip()
            if not story_time:
                errors.append(f"{ctx}: missing 'story_time'")

            unlock = msg.get("unlock")
            unlock_on = ""
            unlock_id = ""
            if not isinstance(unlock, dict):
                errors.append(f"{ctx}: 'unlock' must be an object")
            else:
                unlock_on = str(unlock.get("on", "")).strip()
                unlock_id = str(unlock.get("id", "")).strip()
                if unlock_on not in VALID_UNLOCK_KINDS:
                    errors.append(
                        f"{ctx}: invalid unlock.on '{unlock_on}' (expected one of {sorted(VALID_UNLOCK_KINDS)})"
                    )
                if not unlock_id:
                    errors.append(f"{ctx}: missing unlock.id")
                elif unlock_on in {"scene_enter", "scene_exit"}:
                    if unlock_id not in valid_scenes:
                        errors.append(f"{ctx}: unlock scene '{unlock_id}' does not exist in story-data.json")
                elif unlock_on == "mission_done":
                    if unlock_id not in valid_missions:
                        errors.append(f"{ctx}: unlock mission '{unlock_id}' does not exist in story-data.json")
                elif unlock_on == "found" and unlock_id.startswith("EX-CH"):
                    if unlock_id not in valid_scenes:
                        errors.append(f"{ctx}: unlock found scene '{unlock_id}' does not exist in story-data.json")

            if "join" not in msg or not isinstance(msg.get("join"), str):
                errors.append(f"{ctx}: missing string field 'join'")
                join_str = ""
            else:
                join_str = str(msg.get("join", "")).strip()
                if chapter_num > 0 and join_str:
                    if join_str not in join_counts:
                        errors.append(f"{ctx}: join '{join_str}' is not in 24_NARRATIVE_REVISION.md §2.9")
                    else:
                        join_counts[join_str] += 1

            subject = str(msg.get("subject", "")).strip()
            if not subject:
                errors.append(f"{ctx}: missing 'subject'")

            body = str(msg.get("body", "")).strip()
            if not body:
                errors.append(f"{ctx}: missing 'body'")
            else:
                word_count = len(body.split())
                if word_count > 60:
                    errors.append(f"{ctx}: body has {word_count} words (max 60)")

            if not isinstance(msg.get("goal"), bool):
                errors.append(f"{ctx}: 'goal' must be a boolean")

            combined_text = f"{sender}\n{subject}\n{body}"
            if BANGLA_RE.search(combined_text):
                errors.append(f"{ctx}: contains Bangla script characters (English only rule)")

            pos = unlock_position(chapter_num, unlock_on, unlock_id, join_str, mission_last_scene)
            if pos < (5, 10):
                for pat in FORBIDDEN_PRE_REVEAL_NAMES:
                    if pat.search(combined_text):
                        errors.append(
                            f"{ctx}: forbidden name '{pat.pattern}' appears before EX-CH05-S10 (unlock position {pos})"
                        )

    if require_all_chapters:
        for ch in range(1, 9):
            if ch not in present_chapters:
                errors.append(f"Missing chapter pack ch{ch:02d}.json")

    for join_id in expected_joins:
        ch_for_join = join_chapter_number(join_id)
        if not require_all_chapters and ch_for_join not in present_chapters:
            continue
        count = join_counts.get(join_id, 0)
        if count < 2:
            errors.append(f"Join '{join_id}' has {count} messages (expected >= 2)")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate campaign message JSON packs.")
    parser.add_argument(
        "--all-chapters",
        action="store_true",
        help="Require all 8 chapter files (ch01.json..ch08.json) to be present.",
    )
    args = parser.parse_args()

    root = repo_root()
    errors = validate_messages(root, require_all_chapters=args.all_chapters)
    if errors:
        for err in errors:
            print(f"ERROR: {err}", file=sys.stderr)
        print(f"check_messages: FAILED ({len(errors)} error(s))", file=sys.stderr)
        return 1

    print("check_messages: PASS (0 errors)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
