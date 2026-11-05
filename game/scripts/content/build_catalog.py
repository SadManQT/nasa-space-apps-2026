#!/usr/bin/env python3
"""Build the checked-in runtime campaign catalog from the canonical sources.

This file is intentionally kept beside the runtime loader so a future content
revision can be regenerated without hand-editing 96 scenes or 388 lines.  It
does not run in Godot; the generated JSON files are the engine inputs.

Line ids are stable keys, not a play order: a line added later keeps the next
free suffix (EX-CH08-S10-L05 is spoken first in its scene).  The play order is
the dialogue array order in story-data.json, which the catalog exposes as
``order`` and ``dialogue_ids``.  Three lines approved on 5 Nov 2026 (M3-94)
ship text-only until M3-94R records them: their ``voice_file`` is empty and the
runtime falls back to captions, as for the two on-screen text lines.
"""

from __future__ import annotations

import copy
import csv
import hashlib
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
STORY_PATH = ROOT / "full-game-story" / "story-data.json"
SCENE_INDEX_PATH = ROOT / "production" / "manifest" / "scene_index.csv"
VO_PATH = ROOT / "production" / "audio" / "vo_lines.csv"
OUTPUT_DIR = ROOT / "game" / "resources" / "campaign" / "content"
FULL_OUTPUT = OUTPUT_DIR / "campaign_catalog.json"
DIALOGUE_OUTPUT = ROOT / "game" / "resources" / "campaign" / "dialogue_catalog.json"


ORIGIN_LABELS = {
    "live": "LOCAL LIVE",
    "radio": "LOCAL RADIO",
    "earth_link": "EARTH LINK",
    "recording": "STORED RECORDING",
    "text": "QUEUED TEXT",
}

SPEAKER_IDS = {
    "Kai": "kai",
    "Amara": "amara",
    "Mei": "mei",
    "Rafi": "rafi",
    "Ferreira": "ferreira",
    "Noor": "noor",
    "Rao": "rao",
    "N.": "n_initial",
    "Engineer": "engineer_2034",
    "Family": "family",
}

SPEAKER_IDENTITIES = {
    "kai": {"display_name": "Kai", "role": "power and heat", "knowledge_status": "known"},
    "amara": {"display_name": "Amara", "role": "atmosphere and measurement", "knowledge_status": "known"},
    "mei": {"display_name": "Mei", "role": "horticulture", "knowledge_status": "known"},
    "rafi": {"display_name": "Rafi", "role": "safety and field operations", "knowledge_status": "known"},
    "ferreira": {"display_name": "Commander Ferreira", "role": "commander and engineer", "knowledge_status": "known"},
    "noor": {"display_name": "Dr Noor Rahman", "role": "botanist and Academy founder", "knowledge_status": "revealed_in_chapter_5"},
    "rao": {"display_name": "Rao", "role": "Earth flight controller", "knowledge_status": "known"},
    "n_initial": {"display_name": "N.", "role": "unidentified gardener recording", "knowledge_status": "unknown_until_chapter_5"},
    "engineer_2034": {"display_name": "2034 Engineer", "role": "stored trial recording", "knowledge_status": "record_identity_only"},
    "family": {"display_name": "Kai's family", "role": "Earth audio", "knowledge_status": "known_sender"},
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def canonical_hash(value: Any) -> str:
    encoded = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"), allow_nan=False).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def base_speaker(value: str) -> str:
    return value.split("(", 1)[0].strip()


def line_knowledge_requirements(speaker: str, scene_id: str, delivery: str) -> list[str]:
    """Knowledge flags a line needs before the runtime may show or speak it.

    Noor's lines wait for her consented identity; every live Earth-link line in
    the Chapter 8 call scenes (Noor's and Rao's) also waits for both verified
    relay legs, so nothing on the restored channel plays before the player has
    verified it.
    """
    requirements: list[str] = []
    if speaker == "Noor":
        requirements.append("noor_identity_revealed")
    if scene_id in {"EX-CH08-S10", "EX-CH08-S12"} and delivery == "earth_link":
        requirements.extend(["relay_local_verified", "relay_earth_verified"])
    return requirements


def load_sources() -> tuple[dict[str, Any], dict[str, dict[str, str]], dict[str, dict[str, str]], dict[str, str]]:
    story = json.loads(STORY_PATH.read_text(encoding="utf-8"))
    scene_rows = list(csv.DictReader(SCENE_INDEX_PATH.open(encoding="utf-8-sig", newline="")))
    vo_rows = list(csv.DictReader(VO_PATH.open(encoding="utf-8-sig", newline="")))
    scene_index = {row["scene"]: row for row in scene_rows}
    vo_index = {row["line_id"]: row for row in vo_rows}
    source_hashes = {
        "story_data_sha256": sha256(STORY_PATH),
        "scene_index_sha256": sha256(SCENE_INDEX_PATH),
        "vo_lines_sha256": sha256(VO_PATH),
    }
    if len(scene_rows) != 96 or len(vo_rows) != 388:
        raise ValueError("canonical source row counts changed; inspect before regenerating")
    return story, scene_index, vo_index, source_hashes


def build_dialogue_line(scene: dict[str, Any], source_line: dict[str, Any], vo: dict[str, str], order: int) -> dict[str, Any]:
    """Build one catalog line; ``order`` is its 1-based play position in the scene."""
    line_id = source_line["id"]
    story_speaker = source_line["speaker"]
    vo_speaker = vo["speaker"]
    speaker_id = SPEAKER_IDS.get(vo_speaker)
    if speaker_id is None:
        raise ValueError(f"unknown VO speaker {vo_speaker!r} for {line_id}")
    if source_line["line"] != vo["text"]:
        raise ValueError(f"story/VO text mismatch for {line_id}")
    delivery = vo["delivery"]
    return {
        "id": line_id,
        "scene_id": scene["id"],
        "order": order,
        "speaker": vo_speaker,
        "speaker_id": speaker_id,
        "speaker_label": base_speaker(story_speaker),
        "source_speaker": story_speaker,
        "speaker_note": vo["speaker_note"],
        "speaker_identity": copy.deepcopy(SPEAKER_IDENTITIES[speaker_id]),
        "delivery": delivery,
        "origin": delivery,
        "origin_label": ORIGIN_LABELS.get(delivery, delivery.upper()),
        "text": vo["text"],
        "line": vo["text"],
        "voice_file": vo["voice_file"],
        "knowledge_required": line_knowledge_requirements(vo_speaker, scene["id"], delivery),
        "knowledge_reveals": [],
        "acknowledgement_completes_predicate": False,
        "evidence_tag": scene["evidenceTag"],
        "source_refs": copy.deepcopy(scene["sourceRefs"]),
    }


def build_choice(scene: dict[str, Any]) -> dict[str, Any]:
    choice = copy.deepcopy(scene.get("choice", {}))
    options = []
    for index, option in enumerate(choice.get("options", []), start=1):
        option_copy = copy.deepcopy(option)
        option_copy["id"] = f"{scene['id']}-OPT{index:02d}"
        option_copy["order"] = index
        option_copy["source_label"] = option_copy.get("label", "")
        options.append(option_copy)
    choice["options"] = options
    choice["id"] = f"{scene['id']}-CHOICE"
    return choice


def build_predicate(scene_id: str, mission_id: str, chapter_id: str, condition: str, source_refs: list[str]) -> dict[str, Any]:
    return {
        "id": f"PRED-{scene_id}-EXIT",
        "type": "scene_exit",
        "owner": "campaign_state",
        "chapter_id": chapter_id,
        "mission_id": mission_id,
        "scene_id": scene_id,
        "expression": condition,
        "responsible_fields": ["scene_predicates", "world_state", "acquired_evidence_ids"],
        "source": "exitCondition",
        "source_refs": copy.deepcopy(source_refs),
        "requires_dialogue_acknowledgement": False,
        "dialogue_acknowledgement_effect": "acknowledge_line_only",
        "completion_event": "scene_completed",
    }


def build_catalog() -> tuple[dict[str, Any], dict[str, Any]]:
    story, scene_index, vo_index, source_hashes = load_sources()
    chapters: list[dict[str, Any]] = []
    missions: list[dict[str, Any]] = []
    scenes: list[dict[str, Any]] = []
    dialogue: list[dict[str, Any]] = []
    predicates: list[dict[str, Any]] = []

    for chapter_number, chapter_source in enumerate(story["chapters"], start=1):
        chapter_id = f"CH{chapter_number:02d}"
        chapter_mission_ids = [mission["id"] for mission in chapter_source["missions"]]
        chapter_scene_ids = [scene["id"] for scene in chapter_source["scenes"]]
        chapter = {
            "id": chapter_id,
            "number": chapter_number,
            "title": chapter_source["title"],
            "subtitle": chapter_source["subtitle"],
            "date": chapter_source["date"],
            "core_minutes": chapter_source["coreMinutes"],
            "mandatory": bool(chapter_source.get("mandatory", True)),
            "summary": chapter_source["summary"],
            "emotional_arc": chapter_source["emotionalArc"],
            "opening_hook": chapter_source["openingHook"],
            "transition_out": chapter_source["transitionOut"],
            "mission_ids": chapter_mission_ids,
            "scene_ids": chapter_scene_ids,
            "learning": copy.deepcopy(chapter_source.get("learning", [])),
            "continuity": copy.deepcopy(chapter_source.get("continuity", [])),
            "production": copy.deepcopy(chapter_source.get("production", [])),
            "completion_predicate_id": f"PRED-{chapter_id}-COMPLETE",
        }
        chapters.append(chapter)

        for mission_order, mission_source in enumerate(chapter_source["missions"], start=1):
            mission_id = mission_source["id"]
            mission_scenes = [scene for scene in chapter_source["scenes"] if scene.get("missionId", scene.get("mission", "")) == mission_id]
            if len(mission_scenes) != 3:
                raise ValueError(f"{mission_id} must contain exactly three scenes")
            mission_scene_ids = [scene["id"] for scene in mission_scenes]
            source_refs: list[str] = []
            for scene in mission_scenes:
                for source_ref in scene["sourceRefs"]:
                    if source_ref not in source_refs:
                        source_refs.append(source_ref)
            mission = {
                "id": mission_id,
                "chapter_id": chapter_id,
                "chapter_number": chapter_number,
                "order": mission_order,
                "title": mission_source["title"],
                "minutes": mission_source["minutes"],
                "goal": mission_source["goal"],
                "scene_ids": mission_scene_ids,
                "source_refs": source_refs,
                "completion_predicate_id": f"PRED-{mission_id}-COMPLETE",
            }
            missions.append(mission)
            predicates.append({
                "id": mission["completion_predicate_id"],
                "type": "mission_complete",
                "owner": "campaign_state",
                "chapter_id": chapter_id,
                "mission_id": mission_id,
                "depends_on": [f"PRED-{scene_id}-EXIT" for scene_id in mission_scene_ids],
                "expression": "all three ordered scene exit predicates are true",
                "responsible_fields": ["completed_scene_ids", "mission_receipts"],
                "source": "mission scene order",
                "source_refs": source_refs,
                "requires_dialogue_acknowledgement": False,
                "dialogue_acknowledgement_effect": "acknowledge_line_only",
                "completion_event": "mission_completed",
            })

        for scene_order, scene_source in enumerate(chapter_source["scenes"], start=1):
            scene_id = scene_source["id"]
            index_row = scene_index.get(scene_id)
            if index_row is None:
                raise ValueError(f"scene index is missing {scene_id}")
            line_entries = []
            for line_order, source_line in enumerate(scene_source["dialogue"], start=1):
                vo = vo_index.get(source_line["id"])
                if vo is None:
                    raise ValueError(f"VO index is missing {source_line['id']}")
                line_entries.append(build_dialogue_line(scene_source, source_line, vo, line_order))
            dialogue.extend(copy.deepcopy(line_entries))
            scene_mission_id = scene_source.get("missionId", scene_source.get("mission", ""))
            predicate = build_predicate(scene_id, scene_mission_id, chapter_id, scene_source["exitCondition"], scene_source["sourceRefs"])
            predicates.append(predicate)
            scene = {
                "id": scene_id,
                "chapter_id": chapter_id,
                "chapter_number": chapter_number,
                "mission_id": scene_mission_id,
                "mission_order": next(index for index, mission in enumerate(chapter_source["missions"], start=1) if mission["id"] == scene_mission_id),
                "order": scene_order,
                "legacy_scene": scene_source["legacyScene"],
                "title": scene_source["title"],
                "minutes": scene_source["minutes"],
                "mandatory": bool(scene_source.get("mandatory", True)),
                "location": scene_source["location"],
                "point_of_view": scene_source["pointOfView"],
                "story_time": scene_source["storyTime"],
                "prose": scene_source["prose"],
                "dialogue_ids": [line["id"] for line in line_entries],
                "dialogue": line_entries,
                "actions": copy.deepcopy(scene_source["playerActions"]),
                "player_actions": copy.deepcopy(scene_source["playerActions"]),
                "choice": build_choice(scene_source),
                "learning": copy.deepcopy(scene_source["learning"]),
                "exit_condition": scene_source["exitCondition"],
                "exit": {
                    "condition": scene_source["exitCondition"],
                    "predicate_id": predicate["id"],
                    "requires_dialogue_acknowledgement": False,
                    "dialogue_acknowledgement_effect": "acknowledge_line_only",
                },
                "evidence_tag": scene_source["evidenceTag"],
                "evidence": {
                    "label": index_row["evidence"],
                    "story_label": scene_source["evidenceTag"],
                    "source": "production/manifest/scene_index.csv",
                    "source_field": "evidence",
                },
                "source_refs": copy.deepcopy(scene_source["sourceRefs"]),
                "knowledge_reveals": ["noor_identity_revealed"] if scene_id == "EX-CH05-S10" else [],
                "predicate_id": predicate["id"],
                "manifest": copy.deepcopy(index_row),
            }
            scenes.append(scene)

    chapter_predicate_ids = []
    for chapter in chapters:
        chapter_predicate = {
            "id": chapter["completion_predicate_id"],
            "type": "chapter_complete",
            "owner": "campaign_state",
            "chapter_id": chapter["id"],
            "depends_on": [mission["completion_predicate_id"] for mission in missions if mission["chapter_id"] == chapter["id"]],
            "expression": "all four ordered mission completion predicates are true",
            "responsible_fields": ["completed_scene_ids", "mission_receipts", "chapter_transition_receipt"],
            "source": "chapter mission order",
            "source_refs": [],
            "requires_dialogue_acknowledgement": False,
            "dialogue_acknowledgement_effect": "acknowledge_line_only",
            "completion_event": "chapter_completed",
        }
        predicates.append(chapter_predicate)
        chapter_predicate_ids.append(chapter_predicate["id"])

    dialogue_payload: dict[str, Any] = {
        "schema_version": 1,
        "catalog_kind": "dialogue",
        "content_revision": "",
        "source_hashes": source_hashes,
        "counts": {"dialogue_lines": len(dialogue), "speakers": len(SPEAKER_IDENTITIES)},
        "speakers": SPEAKER_IDENTITIES,
        "origins": ORIGIN_LABELS,
        "lines": dialogue,
        "acknowledgement_contract": {
            "verb": "acknowledge_line",
            "mutates": ["acknowledged_line_ids", "dialogue_cursor"],
            "completes_predicates": [],
            "grants_knowledge": [],
            "note": "Acknowledging a caption is not a physical operation or scene/mission completion.",
        },
    }
    dialogue_payload["catalog_hash"] = canonical_hash(dialogue_payload)

    catalog: dict[str, Any] = {
        "schema_version": 1,
        "catalog_kind": "campaign",
        "content_revision": "",
        "source_file": "full-game-story/story-data.json",
        "source_hashes": source_hashes,
        "counts": {"chapters": len(chapters), "missions": len(missions), "scenes": len(scenes), "dialogue_lines": len(dialogue), "predicates": len(predicates)},
        "chapters": chapters,
        "missions": missions,
        "scenes": scenes,
        "dialogue": dialogue,
        "predicates": predicates,
        "predicate_rules": {
            "dialogue_acknowledgement": copy.deepcopy(dialogue_payload["acknowledgement_contract"]),
            "scene_completion": "Only the responsible world-state predicate can emit scene_completed.",
            "mission_completion": "Only ordered scene exit predicates can emit mission_completed.",
        },
        "learning_edition": copy.deepcopy(story.get("learning", {})),
        "pacing": copy.deepcopy(story.get("pacing", {})),
        "audit_summary": story.get("auditSummary", ""),
    }
    revision_seed = {
        "story_data_sha256": source_hashes["story_data_sha256"],
        "scene_index_sha256": source_hashes["scene_index_sha256"],
        "vo_lines_sha256": source_hashes["vo_lines_sha256"],
        "schema_version": catalog["schema_version"],
    }
    revision = "campaign-content-1-" + canonical_hash(revision_seed)[:16]
    catalog["content_revision"] = revision
    dialogue_payload["content_revision"] = revision
    catalog["catalog_hash"] = canonical_hash(catalog)
    dialogue_payload.pop("catalog_hash", None)
    dialogue_payload["catalog_hash"] = canonical_hash(dialogue_payload)
    return catalog, dialogue_payload


def write_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    catalog, dialogue = build_catalog()
    write_json(FULL_OUTPUT, catalog)
    write_json(DIALOGUE_OUTPUT, dialogue)
    print(f"wrote {FULL_OUTPUT} ({catalog['catalog_hash']})")
    print(f"wrote {DIALOGUE_OUTPUT} ({dialogue['catalog_hash']})")
