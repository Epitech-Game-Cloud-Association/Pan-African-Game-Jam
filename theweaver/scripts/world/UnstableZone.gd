extends Area2D

# ── PARAMÈTRES ───────────────────────────────────────────────────
@export var base_expansion_rate: float = 2.0   # px/sec
@export var min_expansion_rate: float = 0.8    # après adaptation IA
@export var death_threshold: int = 3           # morts avant adaptation
@export var is_dynamic: bool = true            # false = zone statique

# ── ÉTAT ─────────────────────────────────────────────────────────
var current_rate: float = 0.0
var expansion_active: bool = true
var checkpoint_ref: int = 0  # checkpoint associé

@onready var collision: CollisionPolygon2D = $CollisionPolygon2D
@onready var visual: Polygon2D = $Polygon2D

func _ready() -> void:
	current_rate = base_expansion_rate
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").checkpoint_reached.connect(_on_checkpoint_reached)
		get_node("/root/GameManager").player_died.connect(_on_player_died)
	body_entered.connect(_on_body_entered)

	if not is_dynamic:
		expansion_active = false

func _physics_process(delta: float) -> void:
	if not is_dynamic or not expansion_active:
		return
	_expand(delta)
	_check_terrain_blocking()

func _expand(delta: float) -> void:
	if not collision or not visual:
		return
	var polygon: PackedVector2Array = collision.polygon
	if polygon.size() == 0:
		return
	var center: Vector2 = _get_center(polygon)
	var expanded: PackedVector2Array = PackedVector2Array()

	for point in polygon:
		var dir: Vector2 = (point - center).normalized()
		expanded.append(point + dir * current_rate * delta)

	collision.polygon = expanded
	visual.polygon = expanded

func _get_center(polygon: PackedVector2Array) -> Vector2:
	var sum: Vector2 = Vector2.ZERO
	for p in polygon:
		sum += p
	return sum / polygon.size()

func _check_terrain_blocking() -> void:
	pass

func pause_expansion(duration: float) -> void:
	expansion_active = false
	await get_tree().create_timer(duration).timeout
	expansion_active = true

# ── IA ADAPTATIVE ────────────────────────────────────────────────
func _on_player_died() -> void:
	if has_node("/root/GameManager"):
		var deaths: int = get_node("/root/GameManager").get_deaths_at(checkpoint_ref)
		if deaths >= death_threshold:
			current_rate = min_expansion_rate
			print("[UnstableZone] Adaptive: rate reduced to ", current_rate)

func _on_checkpoint_reached(_id: int) -> void:
	pause_expansion(3.0)

# ── CONTACT JOUEUR ───────────────────────────────────────────────
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("die"):
		body.die()
