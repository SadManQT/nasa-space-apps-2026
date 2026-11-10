## M4-16: the red atmospheric rim is gated to totality (M4-01). The shared live screen in
## monitor/eclipse_camera_view.gdshader used to add rim * gain at every phase, so the ingress frame
## showed a faint red Earth-limb ring before totality. eclipse_monitor_screen.gd now sets the
## shader's rim_visible uniform from ring_visible(phase). This suite guards that gate without
## rendering: in this headless environment frames are never drawn (RenderingServer.frame_post_draw
## never fires), so no pixel of a rendered frame can be read here — the rendered ingress/totality/
## egress frame check must be run on a real-asset copy with a window (see the M4-16 report). What
## this suite does prove headlessly: set_phase drives rim_visible to exactly 1 at totality and 0
## everywhere else, the shader multiplies the rim by that uniform, and the 3.5 ratio and science
## labels are intact. The gate lives on the one shared live screen material, so both
## PR_EclipseMonitor LODs (which share that screen's ViewportTexture, covered by
## test_eclipse_props on real assets) show the gated picture.
## Headless: game/tools/run_tests.sh eclipse_rim_gate
extends SceneTree

const ScreenScript = preload("res://assets/props/eclipse_power/monitor/eclipse_monitor_screen.gd")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	var screen = ScreenScript.new()
	root.add_child(screen)
	var material := screen.get_node("CameraView").get("material") as ShaderMaterial
	# the shader gates the rim by the rim_visible uniform, and the uniform exists on the material
	var code := (material.shader as Shader).code
	_check(code.contains("uniform float rim_visible"), "shader declares the rim_visible uniform")
	_check(code.contains("rim * gain * rim_visible"), "shader multiplies the rim by rim_visible (rim * gain * rim_visible)")
	# the gate condition itself: the rim is on exactly while the Sun is fully hidden
	_check(screen.ring_visible(0.5) and not screen.ring_visible(0.12) and not screen.ring_visible(0.88),
		"ring_visible is true only mid-eclipse (totality)")
	_check(is_equal_approx(screen.visible_fraction(0.0), 1.0) and is_equal_approx(screen.visible_fraction(1.0), 1.0),
		"the Sun is whole before first and after last contact")
	# set_phase drives the uniform at every phase: 1 only in totality, 0 at ingress and egress
	var totality_seen := false
	var rim_on_outside_totality := false
	var rim_off_inside_totality := false
	for step in 51:
		var phase := float(step) / 50.0
		screen.set_phase(phase)
		var rim := float(material.get_shader_parameter("rim_visible"))
		var total := screen.ring_visible(phase)
		totality_seen = totality_seen or total
		if total and not is_equal_approx(rim, 1.0):
			rim_off_inside_totality = true
		if not total and not is_equal_approx(rim, 0.0):
			rim_on_outside_totality = true
		_check(is_equal_approx(rim, 1.0 if total else 0.0),
			"rim_visible is %s at phase %.2f (ring_visible %s)" % ["1" if total else "0", phase, total])
	_check(totality_seen, "the phase sweep reaches totality")
	_check(not rim_on_outside_totality, "the rim is never on outside totality")
	_check(not rim_off_inside_totality, "the rim is never off inside totality")
	# named phases, as the board logs them
	for entry in [[0.2, false, "ingress"], [0.5, true, "totality"], [0.88, false, "egress"]]:
		screen.set_phase(float(entry[0]))
		_check(is_equal_approx(float(material.get_shader_parameter("rim_visible")), 1.0 if entry[1] else 0.0),
			"rim_visible is %s at %s" % ["1" if entry[1] else "0", entry[2]])
	# the 3.5 Earth/Sun width ratio and the science labels are intact
	_check(is_equal_approx(float(screen.data.science.earth_to_sun_width_ratio), 3.5), "Earth/Sun width ratio still 3.5")
	_check(screen.eclipse_date() == "12 Jan 2047", "date from the NASA fixture: %s" % screen.eclipse_date())
	var words := "\n".join(screen.all_text())
	_check(words.contains("12 Jan 2047") and words.contains("(checked)") and words.contains("scenario"), "checked date and scenario geometry labelled apart")
	_check(words.contains("not to scale") and words.contains("not a map of Earth") and words.contains("limb"), "inset labelled conceptual, not to scale, not a map")
	screen.free()
	print("ECLIPSE RIM GATE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
