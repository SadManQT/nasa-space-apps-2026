# Campaign Message Packs (`game/resources/campaign/content/messages/`)

This folder holds the authored in-world message packs delivered to the cadet's **Messages** inbox (`CommsService` / `CommsPanel`).

## Files

- `ch01.json` .. `ch08.json` — Chapter 1 through Chapter 8 campaign message packs.
- `ch00.json` — Two-message sample fixture used by automated tests (`game/tools/test_comms.gd`).

## Schema

Each chapter file is a UTF-8 JSON object:

```json
{
  "chapter": 1,
  "messages": [
    {
      "id": "MSG-CH01-001",
      "thread": "commander",
      "sender": "Commander",
      "story_time": "2046-04-11T06:00Z",
      "unlock": {
        "on": "scene_enter",
        "id": "EX-CH01-S01"
      },
      "join": "CH01 S01→S02",
      "subject": "Welcome to Shackleton Base",
      "body": "Short in-world message body (60 words or fewer).",
      "goal": true
    }
  ]
}
```

### Field Reference

| Field | Type | Description |
|---|---|---|
| `id` | `string` | Globally unique message ID (`MSG-CHxx-NNN`). Never shown on player-visible UI labels. |
| `thread` | `string` | One of the five inbox threads: `crew`, `commander`, `earth`, `academy`, `archive`. |
| `sender` | `string` | In-world sender display name (e.g. `"Commander"`, `"Nadia"`, `"Maa"`, `"Academy Registrar"`). |
| `story_time` | `string` | ISO-8601 UTC timestamp (`YYYY-MM-DDTHH:MMZ`). Formatted as a human date in the UI. |
| `unlock.on` | `string` | Unlock trigger kind: `scene_enter`, `scene_exit`, `mission_done`, `job_done`, or `found`. |
| `unlock.id` | `string` | Target scene ID (`EX-CHxx-Sxx`), mission ID (`EX-Mxxxx`), job receipt ID, or evidence/discovery ID. |
| `join` | `string` | Bridge label from `game-design/24_NARRATIVE_REVISION.md` §2.9 (e.g. `CH01 S01→S02`, `CH01→CH02`). |
| `subject` | `string` | Short in-world subject line. |
| `body` | `string` | In-world message body (`<= 60` words, plain English only). |
| `goal` | `bool` | When `true`, hands off the next step to the HUD goal context during scene bridges. |

## Validation

Run the standalone validator from the repository root:

```bash
python3 production/tools/check_messages.py
```

The validator checks:
1. Every join in `game-design/24_NARRATIVE_REVISION.md` §2.9 for the present chapter packs has at least 2 messages.
2. Every message `id` is globally unique.
3. Every `thread` belongs to `{"crew", "commander", "earth", "academy", "archive"}`.
4. Every `unlock.on` belongs to `{"scene_enter", "scene_exit", "mission_done", "job_done", "found"}` and referenced scene/mission IDs exist in `full-game-story/story-data.json`.
5. Every `body` is at most 60 words.
6. All text is English only (no Bangla script characters `U+0980..U+09FF`).
7. The names `"Noor"` and `"Rahman"` never appear before `EX-CH05-S10`.
