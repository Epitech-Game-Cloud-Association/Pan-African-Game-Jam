# THE WEAVER — Base Projet Godot 4
**GameCloud · Pan African Game Jam**

---

## 📁 STRUCTURE DE FICHIERS

```
the_weaver/
├── project.godot
├── export_presets.cfg
│
├── scenes/
│   ├── core/
│   │   ├── GameManager.tscn        # Autoload — état global du jeu
│   │   ├── SceneTransition.tscn    # Fondu entre scènes
│   │   └── InputHandler.tscn       # Gestion input mobile/desktop
│   │
│   ├── ui/
│   │   ├── MainMenu.tscn
│   │   ├── HUD.tscn                # Needle cooldown, health thread
│   │   ├── PauseMenu.tscn
│   │   ├── LoreFragment.tscn       # Modal fragment de lore
│   │   └── EndScreen.tscn          # Choix final repair/tear
│   │
│   ├── world/
│   │   ├── zones/
│   │   │   └── ZoneInverse.tscn    # La zone prototype
│   │   ├── Checkpoint.tscn
│   │   ├── UnstableZone.tscn
│   │   ├── LorePickup.tscn
│   │   └── ExitRift.tscn           # La grande déchirure de sortie
│   │
│   └── player/
│       ├── Player.tscn
│       └── NeedleEffect.tscn       # VFX du pli spatial
│
├── scripts/
│   ├── core/
│   │   ├── GameManager.gd
│   │   ├── SceneTransition.gd
│   │   └── InputHandler.gd
│   │
│   ├── player/
│   │   ├── Player.gd
│   │   ├── PlayerMovement.gd
│   │   ├── PlayerNeedle.gd         # Mécanique de pli spatial
│   │   └── PlayerState.gd          # State machine du joueur
│   │
│   ├── world/
│   │   ├── ZoneBase.gd             # Classe parente pour toutes les zones
│   │   ├── ZoneInverse.gd
│   │   ├── Checkpoint.gd
│   │   ├── UnstableZone.gd
│   │   └── ExitRift.gd
│   │
│   └── ui/
│       ├── HUD.gd
│       └── LoreFragment.gd
│
├── assets/
│   ├── sprites/
│   │   ├── player/
│   │   ├── world/
│   │   └── ui/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   └── fonts/
│
└── resources/
    ├── PlayerData.tres             # Resource custom état joueur
    ├── ZoneConfig.tres             # Config par zone (gravité, palette...)
    └── LoreFragmentData.tres
```

---

## ⚙️ AUTOLOADS (project.godot)

À configurer dans **Project → Project Settings → Autoload** :

| Nom | Scène/Script | Rôle |
|-----|-------------|------|
| `GameManager` | `scenes/core/GameManager.tscn` | État global, score, save |
| `SceneTransition` | `scenes/core/SceneTransition.tscn` | Transitions entre scènes |
| `InputHandler` | `scenes/core/InputHandler.gd` | Swipe, tap, mobile input |
| `AudioManager` | `scripts/core/AudioManager.gd` | Music + SFX global |

---

## 🎮 SCÈNE PRINCIPALE — Player.tscn

```
Player (CharacterBody2D)
├── CollisionShape2D          # CapsuleShape2D
├── Sprite2D                  # ou AnimatedSprite2D
├── AnimationPlayer
├── NeedleCooldownTimer (Timer)
├── CoyoteTimer (Timer)       # 6 frames = ~0.1s à 60fps
├── JumpBufferTimer (Timer)   # 6 frames = ~0.1s
├── NeedleRange (Area2D)      # Détection zone de pli
│   └── CollisionShape2D      # CircleShape2D r=120px
└── HitBox (Area2D)           # Pour les zones instables
    └── CollisionShape2D
```

---

## 📝 GameManager.gd

```gdscript
# scripts/core/GameManager.gd
extends Node

# ── SIGNAUX ──────────────────────────────────────────────────────
signal checkpoint_reached(checkpoint_id: int)
signal player_died
signal zone_entered(zone_name: String)
signal lore_collected(lore_id: int)
signal game_completed(choice: String)  # "repair" ou "tear"

# ── ÉTAT GLOBAL ──────────────────────────────────────────────────
var current_zone: String = ""
var current_checkpoint: int = 0
var death_count: int = 0
var deaths_at_checkpoint: Dictionary = {}  # {checkpoint_id: count}
var lore_collected: Array[int] = []
var gravity_inverted: bool = false

# ── SAVE STATE ───────────────────────────────────────────────────
var player_spawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	print("[GameManager] Initialized")

func register_death(at_checkpoint: int) -> void:
	death_count += 1
	deaths_at_checkpoint[at_checkpoint] = \
		deaths_at_checkpoint.get(at_checkpoint, 0) + 1
	player_died.emit()

func get_deaths_at(checkpoint_id: int) -> int:
	return deaths_at_checkpoint.get(checkpoint_id, 0)

func set_checkpoint(checkpoint_id: int, position: Vector2) -> void:
	current_checkpoint = checkpoint_id
	player_spawn_position = position
	checkpoint_reached.emit(checkpoint_id)

func collect_lore(lore_id: int) -> void:
	if lore_id not in lore_collected:
		lore_collected.append(lore_id)
		lore_collected.emit(lore_id)

func reset_zone() -> void:
	death_count = 0
	deaths_at_checkpoint.clear()
	lore_collected.clear()
	current_checkpoint = 0
```

---

## 🏃 Player.gd — Mouvement + Gravité inversée

```gdscript
# scripts/player/Player.gd
extends CharacterBody2D

# ── PARAMÈTRES ───────────────────────────────────────────────────
@export var speed: float = 200.0
@export var jump_force: float = 400.0
@export var gravity_scale_normal: float = 1.0
@export var gravity_scale_inverted: float = -1.0

# Timers (en frames à 60fps)
const COYOTE_FRAMES: int = 6
const JUMP_BUFFER_FRAMES: int = 6

# ── ÉTAT INTERNE ─────────────────────────────────────────────────
var gravity_inverted: bool = false
var coyote_frames_left: int = 0
var jump_buffer_frames: int = 0
var was_on_floor: bool = false
var is_dead: bool = false

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var needle: Node = $NeedleComponent  # script séparé
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer

func _ready() -> void:
	GameManager.player_died.connect(_on_player_died)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_handle_gravity(delta)
	_handle_movement()
	_handle_jump()
	_update_coyote()
	_update_jump_buffer()
	move_and_slide()
	_update_animation()

# ── GRAVITÉ ──────────────────────────────────────────────────────
func _handle_gravity(delta: float) -> void:
	var base_gravity: float = ProjectSettings.get_setting(
		"physics/2d/default_gravity"
	)
	var direction: float = -1.0 if gravity_inverted else 1.0
	velocity.y += base_gravity * direction * delta

func set_gravity_inverted(inverted: bool) -> void:
	gravity_inverted = inverted
	GameManager.gravity_inverted = inverted

# ── MOUVEMENT ────────────────────────────────────────────────────
func _handle_movement() -> void:
	var input_dir: float = Input.get_axis("move_left", "move_right")
	if input_dir != 0:
		velocity.x = input_dir * speed
		$Sprite2D.flip_h = input_dir < 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed * 0.2)

# ── SAUT (context-sensible selon gravité) ─────────────────────────
func _handle_jump() -> void:
	var on_floor: bool = _is_grounded()

	# Coyote time
	if was_on_floor and not on_floor:
		coyote_frames_left = COYOTE_FRAMES
	was_on_floor = on_floor

	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_frames = JUMP_BUFFER_FRAMES

	# Exécuter le saut
	var can_jump: bool = on_floor or coyote_frames_left > 0
	if jump_buffer_frames > 0 and can_jump:
		# Inversé : le "saut" pousse vers le bas (direction opposée à la gravité)
		var jump_dir: float = 1.0 if gravity_inverted else -1.0
		velocity.y = jump_force * jump_dir
		jump_buffer_frames = 0
		coyote_frames_left = 0

func _is_grounded() -> bool:
	# En gravité inversée, "sol" = plafond
	return is_on_floor() if not gravity_inverted else is_on_ceiling()

func _update_coyote() -> void:
	if coyote_frames_left > 0:
		coyote_frames_left -= 1

func _update_jump_buffer() -> void:
	if jump_buffer_frames > 0:
		jump_buffer_frames -= 1

# ── MORT & RESPAWN ───────────────────────────────────────────────
func die() -> void:
	if is_dead:
		return
	is_dead = true
	anim.play("death")
	GameManager.register_death(GameManager.current_checkpoint)
	await get_tree().create_timer(1.0).timeout
	respawn()

func respawn() -> void:
	is_dead = false
	global_position = GameManager.player_spawn_position
	velocity = Vector2.ZERO
	anim.play("idle")

func _on_player_died() -> void:
	pass  # Géré par die()

# ── ANIMATION ────────────────────────────────────────────────────
func _update_animation() -> void:
	if is_on_floor():
		if abs(velocity.x) > 10:
			anim.play("run")
		else:
			anim.play("idle")
	else:
		anim.play("jump")
```

---

## 🪡 PlayerNeedle.gd — Mécanique de Pli Spatial

```gdscript
# scripts/player/PlayerNeedle.gd
extends Node

# ── PARAMÈTRES ───────────────────────────────────────────────────
@export var max_range: float = 120.0      # pixels
@export var cooldown_duration: float = 2.0
@export var min_swipe_length: float = 40.0  # pixels mobile

# ── ÉTAT ─────────────────────────────────────────────────────────
var is_ready: bool = true
var swipe_start: Vector2 = Vector2.ZERO
var is_swiping: bool = false

@onready var player: CharacterBody2D = get_parent()
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var needle_range: Area2D = player.get_node("NeedleRange")

signal needle_used(from: Vector2, to: Vector2)
signal needle_blocked(position: Vector2)
signal cooldown_started(duration: float)
signal cooldown_finished

func _ready() -> void:
	cooldown_timer.wait_time = cooldown_duration
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_finished)

func _input(event: InputEvent) -> void:
	# ── MOBILE : Swipe ─────────────────────────────────────────
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
			is_swiping = true
		else:
			is_swiping = false

	if event is InputEventScreenDrag and is_swiping:
		var swipe_vec: Vector2 = event.position - swipe_start
		if swipe_vec.length() >= min_swipe_length:
			_try_needle(swipe_vec.normalized())
			is_swiping = false

	# ── DESKTOP : Clic droit pour tester ───────────────────────
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var dir: Vector2 = (get_viewport().get_mouse_position() \
				- player.global_position).normalized()
			_try_needle(dir)

func _try_needle(direction: Vector2) -> void:
	if not is_ready:
		return

	var target: Vector2 = player.global_position + direction * max_range

	# Vérifier collision terrain
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		player.global_position, target,
		0b00000010  # layer terrain uniquement
	)
	var result = space_state.intersect_ray(query)

	if result:
		# Bloqué — effet de rejet
		needle_blocked.emit(result.position)
		_play_blocked_effect()
		return

	# Pli réussi
	_execute_fold(target)

func _execute_fold(target: Vector2) -> void:
	player.global_position = target
	player.velocity = Vector2.ZERO  # reset momentum
	needle_used.emit(player.global_position, target)
	_start_cooldown()
	_play_fold_effect(target)

func _start_cooldown() -> void:
	is_ready = false
	cooldown_timer.start()
	cooldown_started.emit(cooldown_duration)

func _on_cooldown_finished() -> void:
	is_ready = true
	cooldown_finished.emit()

func _play_fold_effect(_at: Vector2) -> void:
	# TODO: instancier NeedleEffect.tscn à la position
	pass

func _play_blocked_effect() -> void:
	# TODO: shake + glow sur l'icône Needle dans le HUD
	pass
```

---

## ☣️ UnstableZone.gd — IA d'expansion

```gdscript
# scripts/world/UnstableZone.gd
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
	GameManager.checkpoint_reached.connect(_on_checkpoint_reached)
	GameManager.player_died.connect(_on_player_died)
	body_entered.connect(_on_body_entered)

	if not is_dynamic:
		expansion_active = false

func _physics_process(delta: float) -> void:
	if not is_dynamic or not expansion_active:
		return
	_expand(delta)
	_check_terrain_blocking()

func _expand(delta: float) -> void:
	var polygon: PackedVector2Array = collision.polygon
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
	# Raycast depuis le centre vers chaque vertex
	# Si collision terrain → ne pas étendre ce vertex
	# (implémentation simplifiée pour la jam)
	pass

func pause_expansion(duration: float) -> void:
	expansion_active = false
	await get_tree().create_timer(duration).timeout
	expansion_active = true

# ── IA ADAPTATIVE ────────────────────────────────────────────────
func _on_player_died() -> void:
	var deaths: int = GameManager.get_deaths_at(checkpoint_ref)
	if deaths >= death_threshold:
		current_rate = min_expansion_rate
		print("[UnstableZone] Adaptive: rate reduced to ", current_rate)

func _on_checkpoint_reached(_id: int) -> void:
	pause_expansion(3.0)

# ── CONTACT JOUEUR ───────────────────────────────────────────────
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.die()
```

---

## 🔖 Checkpoint.gd

```gdscript
# scripts/world/Checkpoint.gd
extends Area2D

@export var checkpoint_id: int = 0

var activated: bool = false

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not activated:
		activate(body.global_position)

func activate(player_pos: Vector2) -> void:
	activated = true
	GameManager.set_checkpoint(checkpoint_id, player_pos)
	anim.play("glow")  # animation couture lumineuse
	# Pausr les zones instables proches
	_notify_nearby_zones()

func _notify_nearby_zones() -> void:
	# Chercher les UnstableZone dans un rayon
	var zones = get_tree().get_nodes_in_group("unstable_zones")
	for zone in zones:
		if zone.global_position.distance_to(global_position) < 300:
			zone.pause_expansion(3.0)
```

---

## 🌀 ZoneBase.gd — Classe parente des zones

```gdscript
# scripts/world/ZoneBase.gd
extends Node2D
class_name ZoneBase

@export var zone_name: String = ""
@export var gravity_inverted: bool = false

func _ready() -> void:
	GameManager.zone_entered.emit(zone_name)
	_setup_zone()

func _setup_zone() -> void:
	# À override dans chaque zone
	pass

func apply_zone_rules(player: CharacterBody2D) -> void:
	player.set_gravity_inverted(gravity_inverted)
```

---

## 📱 InputHandler.gd — Mobile + Desktop unifié

```gdscript
# scripts/core/InputHandler.gd
extends Node

# Actions à mapper dans Project → Input Map :
# "move_left"   → A, flèche gauche, joystick gauche X-
# "move_right"  → D, flèche droite, joystick gauche X+
# "jump"        → Espace, W, flèche haut, bouton A manette
# "pause"       → Échap, Start manette

# Le swipe pour le Needle est géré directement
# dans PlayerNeedle.gd via InputEventScreenDrag

signal swipe_detected(direction: Vector2, length: float)

var _touch_start: Dictionary = {}  # {finger_id: Vector2}

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start[event.index] = event.position
		elif event.index in _touch_start:
			var start: Vector2 = _touch_start[event.index]
			var swipe: Vector2 = event.position - start
			if swipe.length() > 30:
				swipe_detected.emit(swipe.normalized(), swipe.length())
			_touch_start.erase(event.index)
```

---

## 🖥️ HUD.gd — Needle cooldown + Health thread

```gdscript
# scripts/ui/HUD.gd
extends CanvasLayer

@onready var needle_arc: TextureProgressBar = $NeedleArc
@onready var thread_bar: TextureProgressBar = $ThreadBar  # "vie"

var max_cooldown: float = 2.0

func _ready() -> void:
	# Connecter aux signaux du Needle via le joueur
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var needle = player.get_node("NeedleComponent")
		needle.cooldown_started.connect(_on_cooldown_started)
		needle.cooldown_finished.connect(_on_cooldown_finished)

func _on_cooldown_started(duration: float) -> void:
	max_cooldown = duration
	var tween = create_tween()
	tween.tween_property(needle_arc, "value", 0.0, duration)

func _on_cooldown_finished() -> void:
	needle_arc.value = 100.0
```

---

## ⚙️ project.godot — Réglages clés

```ini
[display]
window/size/viewport_width=390
window/size/viewport_height=844
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[physics]
2d/default_gravity=980

[input]
move_left={...}
move_right={...}
jump={...}
pause={...}

[autoload]
GameManager="*res://scenes/core/GameManager.tscn"
SceneTransition="*res://scenes/core/SceneTransition.tscn"
InputHandler="*res://scripts/core/InputHandler.gd"
AudioManager="*res://scripts/core/AudioManager.gd"
```

---

## 🏷️ GROUPES (à assigner dans l'inspecteur Godot)

| Groupe | Nœuds |
|--------|-------|
| `player` | Player.tscn |
| `unstable_zones` | Toutes les UnstableZone |
| `checkpoints` | Tous les Checkpoint |
| `lore_pickups` | Tous les LorePickup |
| `terrain` | TileMapLayer du sol/plateformes |

---

## 🔀 COLLISION LAYERS

| Layer | Nom | Usage |
|-------|-----|-------|
| 1 | `terrain` | Sol, murs, plateformes |
| 2 | `player` | Le joueur |
| 3 | `hazards` | Zones instables |
| 4 | `interactables` | Checkpoints, lore, exit rift |
| 5 | `needle_check` | Raycast du Needle |

---

## ✅ ORDRE D'IMPLÉMENTATION (Jours 1–4)

```
Jour 1
  [x] Créer le projet Godot 4
  [x] Configurer project.godot (résolution, gravité, input map)
  [x] Créer l'arborescence de dossiers
  [x] Player.tscn avec CollisionShape2D + Sprite2D placeholder
  [x] Player.gd — mouvement horizontal de base

Jour 2
  [x] Gravité inversée dans Player.gd
  [x] Coyote time (6 frames) + jump buffer (6 frames)
  [x] GameManager.gd — autoload basique
  [x] Zone de test simple (sol + plafond) pour valider la gravité

Jour 3
  [x] PlayerNeedle.gd — swipe detection + fold
  [x] Raycast terrain blocking
  [x] CooldownTimer + signal vers HUD
  [x] UnstableZone.gd — expansion basique

Jour 4
  [x] Mort + respawn (Player.die() / Player.respawn())
  [x] Checkpoint.gd
  [x] IA adaptative UnstableZone (death_counter)
  [x] Test boucle complète : spawn → mort → respawn → checkpoint
```
