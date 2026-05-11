## EndScreen.gd
## Écran de fin — choix Repair / Tear.
## Dev 2 · Jour 5
extends Control

@onready var _btn_repair: Button = $VBox/ButtonRepair
@onready var _btn_tear:   Button = $VBox/ButtonTear

func _ready() -> void:
	_btn_repair.pressed.connect(func(): _choose("repair"))
	_btn_tear.pressed.connect(func():   _choose("tear"))

func _choose(choice: String) -> void:
	GameManager.complete_game(choice)
	await get_tree().create_timer(0.5).timeout
	SceneTransition.change_scene("res://scenes/ui/Credits.tscn")
