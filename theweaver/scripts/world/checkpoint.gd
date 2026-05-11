## Checkpoint.gd
## Couture lumineuse — sauvegarde + pause UnstableZones proches.

extends Area2D

@export var checkpoint_id:  String = "cp-1"
@export var pause_radius:   float  = 300.0
@export var pause_duration: float  = 3.0

@onready var _anim:  AnimationPlayer   = $AnimationPlayer
@onready var _audio: AudioStreamPlayer = $AudioStreamPlayer

var _activated: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _activated or not body.is_in_group("player"):
		return
	_activated = true

	GameManager.set_checkpoint(checkpoint_id, body.global_position)

	if _anim and _anim.has_animation("activate"):
		_anim.play("activate")
	if _audio and _audio.stream:
		_audio.play()

	_pause_nearby_zones()

func _pause_nearby_zones() -> void:
	for zone in get_tree().get_nodes_in_group("unstable_zone"):
		if zone is Node2D:
			if global_position.distance_to(zone.global_position) <= pause_radius:
				if zone.has_method("pause_expansion"):
					zone.pause_expansion(pause_duration)
