extends Area2D
var _speed : float = 150.0
var _lifetime : float = 2.0
var _radius : float = 10.0
var _timer : float = 0.0
var _points : int = 32

@onready var _shape : CollisionShape2D = $CollisionShape2D
@onready var _line : Line2D = $VisualRing/Line2D

func init(speed: float, lifetime: float) -> void:
	_speed = speed
	_lifetime = lifetime
	body_entered.connect(_on_body_entered)
	_update_visuals()

func _physics_process(delta: float) -> void:
	_timer += delta
	_radius += _speed * delta
	_update_shape()
	_update_visuals() 
	if _timer >= _lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("die"):
			body.die()

func _update_shape() -> void:
	if _shape and _shape.shape is CircleShape2D:
		(_shape.shape as CircleShape2D).radius = _radius

func _update_visuals() -> void:
	if not _line:
		return
	var pts := PackedVector2Array()
	for i in range(_points + 1):
		var angle := (float(i) / float(_points)) * TAU
		pts.append(Vector2(cos(angle), sin(angle)) * _radius)
	_line.points = pts
