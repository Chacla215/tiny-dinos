extends Node2D
## Throwaway rig validator. Instantiates DinoRig in isolation and snapshots a
## fixed frame set (idle / walk cycle / attack / hit flail) to /tmp/ralph/ so we
## can eyeball the limb motion without a full match. Run windowed (headless can't
## draw):  /opt/homebrew/bin/godot scenes/rig_test.tscn -- --shot [dino]
## Pair with montage_rig.py to tile the frames into one contact sheet.
## Not shipped — delete after the rig is tuned.

const WIN := Vector2i(460, 440)

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var dino := "ralph"
	for a in args:
		if a != "--shot" and not a.begins_with("--"):
			dino = a
	get_window().size = WIN
	var bg := ColorRect.new()
	bg.color = Color(0.35, 0.40, 0.48)
	bg.size = Vector2(WIN)
	add_child(bg)
	if "--shot" in args:
		_run(dino)

func _make_rig(dino: String) -> DinoRig:
	var r := DinoRig.new()
	r.scale = Vector2(2.2, 2.2)
	r.position = Vector2(230, 300)
	r.build_for(dino, null)
	add_child(r)
	return r

func _run(dino: String) -> void:
	var r := _make_rig(dino)
	if not r.valid:
		push_error("rig invalid for %s — parts missing?" % dino)
		get_tree().quit(1)
		return
	r.play("idle")
	await _wait(0.7)
	await _shot(dino, 0)             # idle
	r.play("walk")
	r.set_walk_speed(260.0)
	r.set_motion(260.0)                       # run right -> body leans into it
	await _wait(0.30); await _shot(dino, 1)   # walk a
	await _wait(0.16); await _shot(dino, 2)   # walk b
	await _wait(0.16); await _shot(dino, 3)   # walk c
	r.play("idle"); r.set_walk_speed(0.0); r.set_motion(0.0)
	await _wait(0.35)
	r.play("attack")
	await _wait(0.06); await _shot(dino, 4)   # attack strike
	r.play("idle")
	await _wait(0.5)
	r.hit(Vector2(1.0, -0.25), 1.4)
	await _wait(0.04); await _shot(dino, 5)   # hit peak
	await _wait(0.10); await _shot(dino, 6)   # overshoot
	await _wait(0.16); await _shot(dino, 7)   # settling
	# floppy stage 2: knocked off its feet, lies limp, scrambles up
	r.topple(Vector2(1.0, -0.2), 1.3)
	await _wait(0.07); await _shot(dino, 8)   # tipping over
	await _wait(0.28); await _shot(dino, 9)   # down / limp
	await _wait(0.70); await _shot(dino, 10)  # getting back up
	# floppy stage 3: carried/grabbed -> limp dangle
	r.set_held(true)
	await _wait(0.25); await _shot(dino, 11)  # hanging limp
	get_tree().quit()

func _wait(secs: float) -> void:
	await get_tree().create_timer(secs).timeout

func _shot(dino: String, idx: int) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("/tmp/ralph")
	img.save_png("/tmp/ralph/seq_%s_%d.png" % [dino, idx])
