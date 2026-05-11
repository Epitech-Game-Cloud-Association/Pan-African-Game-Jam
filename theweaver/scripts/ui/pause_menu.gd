## PauseMenu.gd
## Overlay pause — RESUME + QUIT.
## GD1 l'intègre dans MainMenu, mais le script est ici.
extends Control

@onready var _btn_resume: Button = $Panel/ButtonResume
@onready var _btn_quit:   Button = $Panel/ButtonQuit

func _ready() -> void:
	_btn_resume.pressed.connect(_on_resume)
	_btn_quit.pressed.connect(_on_quit)

func open() -> void:
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func _on_resume() -> void:
	close()

func _on_quit() -> void:
	get_tree().paused = false
	SceneTransition.change_scene("res://scenes/ui/MainMenu.tscn")
