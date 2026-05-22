extends Node2D
# Standalone preview: hand-drawn Ralph vs the current pixel T-Rex, side by side,
# at identical in-game scale, cycling idle -> walk -> Chomp. Press F6 / Play Scene.

const SHEET_HD := "res://assets/sprites/trex_handdrawn.png"
const SHEET_REF := "res://assets/sprites/rynosaurlandcharacters.png"

const HD := {
	"idle":   {"loop": true,  "speed": 5.0,  "rects": [Rect2(0, 0, 151, 110), Rect2(151, 0, 151, 110)]},
	"walk":   {"loop": true,  "speed": 9.0,  "rects": [Rect2(302, 0, 151, 110), Rect2(453, 0, 151, 110), Rect2(604, 0, 151, 110), Rect2(755, 0, 151, 110)]},
	"attack": {"loop": false, "speed": 11.0, "rects": [Rect2(906, 0, 151, 110), Rect2(1057, 0, 151, 110), Rect2(1208, 0, 151, 110)]},
}
const PIX := {
	"idle":   {"loop": true,  "speed": 4.0,  "rects": [Rect2(221, 4, 19, 21), Rect2(247, 3, 19, 22)]},
	"walk":   {"loop": true,  "speed": 8.0,  "rects": [Rect2(219, 30, 20, 21), Rect2(245, 29, 20, 22)]},
	"attack": {"loop": false, "speed": 12.0, "rects": [Rect2(245, 29, 20, 22)]},
}

@onready var hd: AnimatedSprite2D = $HD
@onready var pix: AnimatedSprite2D = $Pix
@onready var state_label: Label = $UI/State

var seq := ["idle", "walk", "attack"]
var idx := 0
var t := 0.0

func _ready() -> void:
	_setup(hd, SHEET_HD, HD, 0.8)
	_setup(pix, SHEET_REF, PIX, 3.6)
	_play(seq[idx])

func _setup(spr: AnimatedSprite2D, path: String, layout: Dictionary, scale: float) -> void:
	if not ResourceLoader.exists(path):
		push_warning("missing sheet: %s" % path)
		return
	var sheet: Texture2D = load(path)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim_name in layout:
		sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, layout[anim_name].loop)
		sf.set_animation_speed(anim_name, layout[anim_name].speed)
		for r in layout[anim_name].rects:
			var at := AtlasTexture.new()
			at.atlas = sheet
			at.region = r
			sf.add_frame(anim_name, at)
	spr.sprite_frames = sf
	spr.scale = Vector2(scale, scale)

func _play(n: String) -> void:
	hd.play(n)
	pix.play(n)
	state_label.text = "playing:  %s" % n.to_upper()

func _process(delta: float) -> void:
	t += delta
	var dur := 1.0 if seq[idx] == "attack" else 1.8
	if t >= dur:
		t = 0.0
		idx = (idx + 1) % seq.size()
		_play(seq[idx])
