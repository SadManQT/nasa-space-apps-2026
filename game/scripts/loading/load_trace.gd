## Opt-in per-step construction timers; disabled during normal play.
extends RefCounted
class_name LoadTrace

static var enabled := false
static var steps: Array = []

static func begin() -> int:
	return Time.get_ticks_usec() if enabled else 0

static func end(label: String, start: int) -> void:
	if enabled and start > 0:
		var finish := Time.get_ticks_usec()
		steps.append({"step": label, "ms": (finish - start) / 1000.0, "start_usec": start, "end_usec": finish, "thread_id": OS.get_thread_caller_id()})
