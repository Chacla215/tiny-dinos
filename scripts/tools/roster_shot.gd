extends Node2D
# Throwaway: render every dino's in-match fighter sprite (the 3D-baked sheets via
# ANIM_LAYOUTS) in a row so we can eyeball the roster as the game actually draws
# them.  Run: godot scenes/roster_shot.tscn  -> /tmp/ralph/roster_ingame.png
const DinoScript = preload("res://scripts/dino.gd")
const ROSTER := ["ralph", "raptor", "trike", "pterry", "bronto", "anky"]

func _ready() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(1280, 360)
	bg.color = Color(0.42, 0.66, 0.82)
	add_child(bg)
	var x := 120.0
	for id in ROSTER:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = DinoScript.build_sprite_frames(id)
		s.position = Vector2(x, 230)
		if s.sprite_frames and s.sprite_frames.has_animation("walk"):
			s.play("walk")
		add_child(s)
		var lbl := Label.new()
		lbl.text = id
		lbl.position = Vector2(x - 40, 300)
		add_child(lbl)
		x += 200.0
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/ralph/roster_ingame.png")
	get_tree().quit()
