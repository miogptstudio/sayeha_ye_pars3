extends CharacterBody3D
## دشمن پایه — تعقیب، حمله، نوار سلامتی

enum Kind { ENEMY, ELITE, BOSS }

@export var kind: Kind = Kind.ENEMY
@export var max_hp: int = 40
@export var damage: int = 8
@export var move_speed: float = 3.2
@export var attack_range: float = 1.8
@export var aggro_range: float = 18.0
@export var attack_cooldown: float = 1.2

var hp: int
var _cooldown: float = 0.0
var _alive: bool = true
var _player: Node3D
var _world: Node3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var hp_bar: Label3D = $HPBar

func _ready() -> void:
	hp = max_hp
	_apply_kind_stats()
	_colorize()
	collision_layer = 4
	collision_mask = 1
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		_player = gm.player
	_world = get_tree().get_first_node_in_group("world")

func _apply_kind_stats() -> void:
	match kind:
		Kind.ENEMY:
			max_hp = 40
			damage = 8
			move_speed = 3.2
			scale = Vector3.ONE
		Kind.ELITE:
			max_hp = 90
			damage = 14
			move_speed = 3.8
			scale = Vector3(1.2, 1.25, 1.2)
		Kind.BOSS:
			max_hp = 280
			damage = 22
			move_speed = 2.6
			aggro_range = 28.0
			scale = Vector3(1.8, 2.0, 1.8)
	hp = max_hp

func _colorize() -> void:
	if not mesh:
		return
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.7
	match kind:
		Kind.ENEMY:
			mat.albedo_color = Color(0.75, 0.15, 0.12)
		Kind.ELITE:
			mat.albedo_color = Color(0.55, 0.12, 0.55)
		Kind.BOSS:
			mat.albedo_color = Color(0.25, 0.05, 0.35)
	mesh.material_override = mat

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if _cooldown > 0.0:
		_cooldown -= delta

	if not _player or not is_instance_valid(_player):
		var gm := get_node_or_null("/root/GameManager")
		if gm:
			_player = gm.player
		return

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	if dist > aggro_range:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	elif dist > attack_range:
		var dir := to_player.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0
		velocity.z = 0
		if _cooldown <= 0.0:
			_do_attack()
			_cooldown = attack_cooldown

	if not is_on_floor():
		velocity.y -= 16.0 * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	_update_hp_bar()

func _do_attack() -> void:
	if _player and _player.has_method("take_damage"):
		_player.take_damage(damage)

func take_damage(amount: int) -> void:
	if not _alive:
		return
	hp = max(0, hp - amount)
	_update_hp_bar()
	if hp <= 0:
		_die()

func _die() -> void:
	_alive = false
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("on_enemy_killed"):
		gm.on_enemy_killed(kind)
	# پاداش ساده
	queue_free()

func _update_hp_bar() -> void:
	if hp_bar:
		hp_bar.text = "%d/%d" % [hp, max_hp]
		hp_bar.visible = hp < max_hp and _alive
