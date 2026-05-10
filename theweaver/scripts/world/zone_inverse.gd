extends ZoneBase

func _setup_zone() -> void:
	zone_name = "ZoneInverse"
	gravity_inverted = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		apply_zone_rules(body)

func _ready() -> void:
	super._ready()

	# connect the Area2D trigger to apply zone rules when player enters the room
	if has_node("ZoneArea"):
		var area = get_node("ZoneArea")
		if area.has_signal("body_entered"):
			area.body_entered.connect(_on_body_entered)

	# connect killzones for simple death handling (hook to player or GameManager)
	if has_node("KillZoneTop"):
		var kz_top = get_node("KillZoneTop")
		if kz_top.has_signal("body_entered"):
			kz_top.body_entered.connect(_on_killzone_entered)
	if has_node("KillZoneBottom"):
		var kz_bot = get_node("KillZoneBottom")
		if kz_bot.has_signal("body_entered"):
			kz_bot.body_entered.connect(_on_killzone_entered)

func _on_killzone_entered(body: Node2D) -> void:
	if not body:
		return
	if body.is_in_group("player"):
		if body.has_method("die"):
			body.die()
		elif has_node("/root/GameManager"):
			get_node("/root/GameManager").player_died.emit()
		else:
			body.queue_free()

