## Opt-in per-step construction timers; disabled during normal play.
extends RefCounted
class_name LoadTrace

static var enabled := false
static var steps: Array = []

static func begin() -> int:
	return Time.get_ticks_usec() if enabled else 0

static func end(label: String, start: int) -> void:
	if enabled and start > 0:
		steps.append({"step": label, "ms": (Time.get_ticks_usec() - start) / 1000.0})
