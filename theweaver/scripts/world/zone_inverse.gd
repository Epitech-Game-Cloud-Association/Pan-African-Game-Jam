## ZoneInverse.gd
## Zone prototype — gravité inversée.
## La logique d'inversion est appliquée par ZoneBase via le Player.
extends Node2D

func _ready() -> void:
	GameManager.zone_entered.emit("L'Inversé")
