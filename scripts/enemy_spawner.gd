extends Node3D
## اسپاون دشمنان اطراف بازیکن

@export var max_enemies: int = 12
@export var spawn_radius: float = 35.0
@export var min_distance: float = 12.0
@export var spawn_interval: float = 4.0

var _timer: float = 2.0
var _enemy_scene: PackedScene
var _world_gen: Node3D

func _ready() -> void:
	_enemy_scene = preload("res://scenes/enemy.tscn")
	_world_gen = get_parent().get_node_or_null("World")

func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = spawn_interval
	_try_spawn()

func _try_spawn() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if not gm or not gm.player:
		return
	var count := get_tree().get_nodes_in_group("enemies").size()
	if count >= max_enemies:
		return

	var player_pos: Vector3 = gm.player.global_position
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var angle := rng.randf() * TAU
	var dist := rng.randf_range(min_distance, spawn_radius)
	var pos := player_pos + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

	if _world_gen and _world_gen.has_method("height_at"):
		pos.y = _world_gen.height_at(pos.x, pos.z) + 0.5
	else:
		pos.y = player_pos.y

	var enemy: CharacterBody3D = _enemy_scene.instantiate()
	# نوع تصادفی — با احتمال کم‌تر elite/boss
	var roll := rng.randf()
	if roll > 0.97:
		enemy.kind = 2  # BOSS
	elif roll > 0.85:
		enemy.kind = 1  # ELITE
	else:
		enemy.kind = 0  # ENEMY
	enemy.global_position = pos
	add_child(enemy)
	enemy.add_to_group("enemies")
