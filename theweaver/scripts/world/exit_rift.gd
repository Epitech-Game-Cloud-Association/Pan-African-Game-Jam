## ExitRift.gd
## Grande Déchirure de sortie — déclenche l'EndScreen.

extends Area2D

@export var end_screen_path: String = "res://scenes/ui/EndScreen.tscn"

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	SceneTransition.change_scene(end_screen_path)
