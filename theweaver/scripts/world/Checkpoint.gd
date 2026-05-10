extends Area2D

@export var checkpoint_id: int = 0

var activated: bool = false

@onready var anim: AnimationPlayer = null # $AnimationPlayer

func _ready() -> void:
	if has_node("AnimationPlayer"):
		anim = get_node("AnimationPlayer")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not activated:
		activate(body.global_position)

func activate(player_pos: Vector2) -> void:
	activated = true
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").set_checkpoint(checkpoint_id, player_pos)
	if anim:
		anim.play("glow")  # animation couture lumineuse
	_notify_nearby_zones()

func _notify_nearby_zones() -> void:
	var zones = get_tree().get_nodes_in_group("unstable_zones")
	for zone in zones:
		if zone.global_position.distance_to(global_position) < 300:
			if zone.has_method("pause_expansion"):
				zone.pause_expansion(3.0)
