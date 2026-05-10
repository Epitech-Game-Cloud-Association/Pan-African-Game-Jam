extends Node2D
class_name ZoneBase

@export var zone_name: String = ""
@export var gravity_inverted: bool = false

func _ready() -> void:
	# Assuming GameManager exists and has zone_entered signal
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").emit_signal("zone_entered", zone_name)
	_setup_zone()

func _setup_zone() -> void:
	# À override dans chaque zone
	pass

func apply_zone_rules(player: CharacterBody2D) -> void:
	if player.has_method("set_gravity_inverted"):
		player.set_gravity_inverted(gravity_inverted)
