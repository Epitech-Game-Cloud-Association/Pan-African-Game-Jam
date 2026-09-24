extends CharacterBody2D
signal boss_defeated

const MOVE_SPEED : float = 80.0
const PULSE_SPEED : float = 150.0
const PULSE_COOLDOWN : float = 4.0
const PULSE_COUNT : int = 3
const PULSE_LIFETIME : float = 2.0
const PULSE_RANGE : float = 100.0
const CHARGE_TIMEOUT : float = 3.0
const IDLE_DURATION : float = 2.0
const MAX_HEALTH : float = 6.0
const SPLIT_THRESHOLD : int = 3
const SPLIT_SPEED : float = 60.0
const HITBOX_RADIUS : float = 30.0

enum State {
	IDLE,
	CHARGE,
	PULSE,
	SPLIT,
	DEATH
}

var state : State = State.IDLE
var health : float = MAX_HEALTH
var is_split : bool = false
var pulse_timer : float = 0.0
var charge_timer : float = 0.0
var idle_timer : float = 0.0
var player_ref : CharacterBody2D = null

@export var pulse_ring_scene : PackedScene
@export var boss_scene       : PackedScene

func _ready() -> void:
	player_ref = get_tree().get_first_node_in_group("player")
	_enter_state(State.IDLE)

func _physics_process(delta: float) -> void:
	if player_ref == null:
		player_ref = get_tree().get_first_node_in_group("player")
		return
	match state:
		State.IDLE: _state_idle(delta)
		State.CHARGE: _state_charge(delta)
		State.PULSE: _state_pulse(delta)
		State.SPLIT: pass
		State.DEATH: pass

func _state_idle(delta: float) -> void:
	idle_timer += delta
	position.y += sin(idle_timer * 2.0) * 0.5
	if idle_timer >= IDLE_DURATION:
		_enter_state(State.CHARGE)

func _state_charge(delta: float) -> void:
	charge_timer += delta
	pulse_timer += delta
	var to_player : Vector2 = (player_ref.global_position - global_position)
	var dist : float = to_player.length()
	if dist > 1.0:
		var speed = SPLIT_SPEED if is_split else MOVE_SPEED
		velocity = to_player.normalized() * speed
		move_and_slide()
	if dist <= PULSE_RANGE or pulse_timer >= PULSE_COOLDOWN:
		_enter_state(State.PULSE)
		return
	if charge_timer >= CHARGE_TIMEOUT:
		charge_timer = 0.0

func _state_pulse(_delta: float) -> void:
	pass

func _enter_state(new_state: State) -> void:
	state = new_state
	match new_state:
		State.IDLE:
			idle_timer  = 0.0
			velocity = Vector2.ZERO
		State.CHARGE:
			charge_timer = 0.0
			pulse_timer = 0.0
		State.PULSE:
			velocity = Vector2.ZERO
			_emit_pulse_rings()
			var t := get_tree().create_timer(1.5)
			t.timeout.connect(func(): _enter_state(State.CHARGE))
		State.SPLIT:
			_do_split()
		State.DEATH:
			_do_death()

func _emit_pulse_rings() -> void:
	if pulse_ring_scene == null:
		push_warning("BossAI: pulse_ring_scene non assignée dans l'inspecteur.")
		return
	for i in range(PULSE_COUNT):
		var ring = pulse_ring_scene.instantiate()
		get_parent().add_child(ring)
		ring.global_position = global_position
		if ring.has_method("init"):
			ring.init(PULSE_SPEED, PULSE_LIFETIME)
	pulse_timer = 0.0

func _do_split() -> void:
	if boss_scene == null:
		push_warning("BossAI: boss_scene non assignée — SPLIT impossible.")
		_enter_state(State.CHARGE)
		return
	var directions := [Vector2.LEFT, Vector2.RIGHT]
	for dir in directions:
		var fragment : CharacterBody2D = boss_scene.instantiate()
		get_parent().add_child(fragment)
		fragment.global_position = global_position + dir * 40.0
		if fragment.has_method("init_as_fragment"):
			fragment.init_as_fragment()
	queue_free()

func init_as_fragment() -> void:
	is_split = true
	health = MAX_HEALTH / 2
	_enter_state(State.CHARGE)

func _do_death() -> void:
	velocity = Vector2.ZERO
	var anim := get_node_or_null("AnimationPlayer")
	if anim:
		anim.play("death")
	var t := get_tree().create_timer(3.0)
	t.timeout.connect(func():
		boss_defeated.emit()
		queue_free()
	)

func take_hit() -> void:
	if state == State.DEATH:
		return
	health -= 1
	if health <= SPLIT_THRESHOLD and not is_split:
		_enter_state(State.SPLIT)
		return
	if health <= 0:
		_enter_state(State.DEATH)
