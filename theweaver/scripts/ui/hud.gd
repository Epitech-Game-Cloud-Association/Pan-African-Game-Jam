## HUD.gd
## Interface tête haute : arc Needle, flash checkpoint, modal lore.
## Dev 2 · Jours 1–4
extends CanvasLayer

@onready var _needle_arc:    TextureProgressBar = $NeedleCooldownArc
@onready var _screen_flash:  ColorRect          = $ScreenFlash

@export var lore_modal_scene: PackedScene

const NEEDLE_COOLDOWN: float = 2.0

var _lore_modal: Control = null

func _ready() -> void:
	_needle_arc.max_value = 100.0
	_needle_arc.value     = 100.0
	_screen_flash.modulate.a    = 0.0
	_screen_flash.mouse_filter  = Control.MOUSE_FILTER_IGNORE

	GameManager.checkpoint_reached.connect(_on_checkpoint_reached)
	GameManager.lore_collected.connect(_on_lore_collected)

# ─── ARC COOLDOWN NEEDLE ───────────────────────────────────────
## Appelé par PlayerNeedle.gd dès que le fold est utilisé.
func start_needle_cooldown() -> void:
	var tw := create_tween()
	tw.tween_property(_needle_arc, "value", 0.0, NEEDLE_COOLDOWN)
	tw.tween_callback(func(): _needle_arc.value = 100.0)

# ─── FLASH CHECKPOINT ──────────────────────────────────────────
func _on_checkpoint_reached(_id: String) -> void:
	_screen_flash.modulate.a = 0.35
	var tw := create_tween()
	tw.tween_property(_screen_flash, "modulate:a", 0.0, 0.5)

# ─── MODAL LORE ────────────────────────────────────────────────
func _on_lore_collected(lore_id: String) -> void:
	if _lore_modal != null or lore_modal_scene == null:
		return
	_lore_modal = lore_modal_scene.instantiate()
	add_child(_lore_modal)
	if _lore_modal.has_method("setup"):
		_lore_modal.setup(lore_id)
	if _lore_modal.has_signal("closed"):
		_lore_modal.closed.connect(func():
			_lore_modal.queue_free()
			_lore_modal = null)
