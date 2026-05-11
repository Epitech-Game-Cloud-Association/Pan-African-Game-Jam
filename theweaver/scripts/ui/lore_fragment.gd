## LoreFragment.gd
## Modal overlay — image de lore + fermeture sur tap.
## Dev 2 · Jour 5
extends Control

signal closed

@export var lore_images: Dictionary = {}

@onready var _image_rect: TextureRect = $Panel/TextureRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

func setup(lore_id: String) -> void:
	if lore_images.has(lore_id) and _image_rect:
		_image_rect.texture = lore_images[lore_id]

func _input(event: InputEvent) -> void:
	var tap   := event is InputEventScreenTouch   and not event.pressed
	var click := event is InputEventMouseButton   \
		and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	if tap or click:
		get_tree().paused = false
		closed.emit()
