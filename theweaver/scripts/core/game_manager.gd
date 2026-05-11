## GameManager.gd
## Autoload — état global du jeu.
extends Node

signal player_died
signal checkpoint_reached(checkpoint_id: String)
signal zone_entered(zone_name: String)
signal lore_collected(lore_id: String)
signal game_completed(choice: String)   # "repair" | "tear"

var player_spawn_position: Vector2 = Vector2.ZERO

## { "cp_id": int }  — morts par checkpoint
var death_counter: Dictionary = {}

var collected_lore: Array[String] = []
var activated_checkpoints: Array[String] = []

func set_checkpoint(checkpoint_id: String, spawn_pos: Vector2) -> void:
	if checkpoint_id in activated_checkpoints:
		return
	activated_checkpoints.append(checkpoint_id)
	player_spawn_position = spawn_pos
	checkpoint_reached.emit(checkpoint_id)

func register_death(checkpoint_id: String) -> void:
	if not death_counter.has(checkpoint_id):
		death_counter[checkpoint_id] = 0
	death_counter[checkpoint_id] += 1
	player_died.emit()

func get_deaths_at(checkpoint_id: String) -> int:
	return death_counter.get(checkpoint_id, 0)

func collect_lore(lore_id: String) -> void:
	if lore_id in collected_lore:
		return
	collected_lore.append(lore_id)
	lore_collected.emit(lore_id)

func complete_game(choice: String) -> void:
	game_completed.emit(choice)
