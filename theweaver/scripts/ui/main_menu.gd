## main_menu.gd
## Écran principal — bouton PLAY, SETTINGS, version.
## (Stub — GD1 implémente la scène complète)
extends Control

func _ready() -> void:
	pass

func _on_play_pressed() -> void:
	SceneTransition.change_scene("res://scenes/world/zones/ZoneInverse.tscn")

func _on_settings_pressed() -> void:
	SceneTransition.change_scene("res://scenes/ui/Settings.tscn")
