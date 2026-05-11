## SceneTransition.gd
## Autoload — fondu noir entre scènes.
##
## Usage :
##   await SceneTransition.fade_to_black()
##   get_tree().change_scene_to_file("res://scenes/...")
##   await SceneTransition.fade_from_black()
##   — OU —
##   SceneTransition.change_scene("res://scenes/...")
extends CanvasLayer

@onready var _overlay: ColorRect       = $Overlay
@onready var _anim:    AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	layer = 100
	_overlay.modulate.a = 0.0

func fade_to_black() -> void:
	_anim.play("fade_in")
	await _anim.animation_finished

func fade_from_black() -> void:
	_anim.play("fade_out")
	await _anim.animation_finished

func change_scene(path: String) -> void:
	await fade_to_black()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await fade_from_black()
