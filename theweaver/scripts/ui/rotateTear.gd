extends TextureRect

@export var speed : float = 15

func _process(delta: float) -> void:
	pivot_offset = size / 2
	rotation_degrees += speed * delta
