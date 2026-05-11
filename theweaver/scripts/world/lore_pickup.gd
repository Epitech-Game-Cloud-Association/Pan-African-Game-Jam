## LorePickup.gd
## Fragment de lore collectible.

extends Area2D

@export var lore_id:    String  = "lore_default"
@export var lore_image: Texture2D

var _collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	GameManager.collect_lore(lore_id)
	hide()
	$CollisionShape2D.set_deferred("disabled", true)
