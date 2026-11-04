extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	print("driver=", AudioServer.get_driver_name() if AudioServer.has_method("get_driver_name") else "?", " buses=", AudioServer.bus_count)
	for i in AudioServer.bus_count: print(" bus ", i, " ", AudioServer.get_bus_name(i))
	print("exists ogg ", ResourceLoader.exists("res://tools/test_data/audio/voice_fixture.ogg"), " fa ", FileAccess.file_exists("res://tools/test_data/audio/voice_fixture.ogg"))
	var s = load("res://tools/test_data/audio/voice_fixture.ogg")
	print("stream ", s, " loop ", s.loop if s else null)
	var p := AudioStreamPlayer.new()
	root.add_child(p)
	p.stream = s
	var done := [false]
	p.finished.connect(func(): done[0] = true)
	p.play()
	await process_frame
	print("playing ", p.playing, " pos ", p.get_playback_position())
	var t := Time.get_ticks_msec()
	while not done[0] and Time.get_ticks_msec() - t < 3000:
		await process_frame
	print("finished ", done[0], " after ms ", Time.get_ticks_msec() - t, " playing ", p.playing)
	var v := VideoStreamPlayer.new()
	root.add_child(v)
	var vs := VideoStreamTheora.new()
	vs.file = "res://assets/cutscenes/CS-01_Arrival.ogv"
	v.stream = vs
	v.play()
	t = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < 1500:
		await process_frame
	print("video playing ", v.is_playing(), " pos ", v.stream_position, " len ", v.get_stream_length(), " tex ", v.get_video_texture())
	quit(0)
