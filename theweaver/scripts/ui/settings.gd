## settings.gd
## Écran paramètres — volume, langue FR/EN.
## GD1 gère le visuel complet, ce script connecte les signaux.
extends Control

@onready var _volume_slider: HSlider = $VBox/VolumeSlider
@onready var _lang_button:   Button  = $VBox/LangButton
@onready var _back_button:   Button  = $VBox/BackButton

var _lang: String = "FR"

func _ready() -> void:
	_volume_slider.value_changed.connect(_on_volume_changed)
	_lang_button.pressed.connect(_on_lang_toggled)
	_back_button.pressed.connect(_on_back)

func _on_volume_changed(value: float) -> void:
	AudioManager.set_volume(value)

func _on_lang_toggled() -> void:
	_lang = "EN" if _lang == "FR" else "FR"
	_lang_button.text = "FR / EN  [%s]" % _lang

func _on_back() -> void:
	SceneTransition.change_scene("res://scenes/ui/MainMenu.tscn")
