extends Control
## Opening cutscene: the boot scene. Plays assets/video/opening.ogv (the
## trailer's cutscene cut — see scripts/tools/trailer_prompts.md) before the
## title screen; boots straight to title while the video doesn't exist yet.
## Any gamepad button skips (gamepad-only convention).

const VIDEO_PATH := "res://assets/video/opening.ogv"
const TITLE_SCENE := "res://scenes/title.tscn"

var _leaving := false

@onready var video: VideoStreamPlayer = $Video

func _ready() -> void:
	if not ResourceLoader.exists(VIDEO_PATH):
		_to_title.call_deferred()
		return
	video.stream = load(VIDEO_PATH)
	video.finished.connect(_to_title)
	video.play()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		_to_title()

func _to_title() -> void:
	if _leaving:
		return
	_leaving = true
	get_tree().change_scene_to_file(TITLE_SCENE)
