# M1-08 review fix pass

Initial independent review of preserved948ef2f: C0/I2/M1. No independent rereview is claimed.

1. Packet/label observations missing: added live packet, label and completion fields in actual/projected readings. New real scan and before/after label assertions fail before the fix (135/16 RED including missing choices), then pass on final source. Parent inspected final scan and label forecast/observed images.
2. One-answer label gate: owner-task M1-115 published real bounded label payload/profile2 in51f91cb, independently reviewed C0/I0/M0. UI now offers both actual labels without a default; real controller wrong selection rejects safely, mouse selects correct choice, shared model previews/commits it. Correct/wrong/type/legacy route coverage is retained.
3. Misleading initial observations: regraded Important for a scientific trainer; static expected zero/span values are explicitly labelled Reference targets. No numeric rule changed.

Additional verification caught large-text projection below the scroll clip and keyboard Enter unable to reach confirmation after focusing a read-only label. Kept real native RED, added keyboard RED, restored Lock in focus, retained valid current focus across deferred callbacks, and scrolled the full predicted observation into view. Final native asserts its whole rectangle fits the actual ScrollContainer clip, not just the window. Plain English 'to' replaces an encoding-corrupted arrow; no font or new colour added.

Final focused139+317+104+29=589 checks, zero failures (4/4). Native606 assertions,34 captures, zero failures/warnings/errors at frozen46398b4. All screenshot hashes/timestamps and12 relevant loaded input hashes verified. Full integrated player-text/all-suite gate and genuine campaign E ownership remain pending; M1-107 owns the latter.
