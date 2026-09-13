extends CharacterBody3D
## بازیکن — حرکت، دوربین، حمله، تعامل

const SPEED := 5.5
const SPRINT_MULT := 1.65
const JUMP_VELOCITY := 5.2
const MOUSE_SENS := 0.0028
const ATTACK_RANGE := 2.4
const ATTACK_DAMAGE := 15

@export var max_hp: int = 100
@export var max_stamina: float = 100.0

var hp: int = 100
var stamina: float = 100.0
var yaw: float = 0.0
var pitch: float = 0.0
var bob: float = 0.0
var hurt_flash: float = 0.0
var char_class: String = "traveler"
var _attack_cd: float = 0.0

@onready var cam_pivot: Node3D = $CamPivot
@onready var camera: Camera3D = $CamPivot/Camera3D
@onready var mesh: MeshInstance3D = $MeshInstance3D

var _gm: Node

func _ready() -> void:
	_gm = get_node_or_null("/root/GameManager")
	if _gm:
		_gm.player = self
	hp = max_hp
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = MOUSE_SENS * (_gm.look_sens if _gm else 1.0)
		yaw -= event.relative.x * sens
		pitch = clampf(pitch - event.relative.y * sens, -1.2, 1.1)
		cam_pivot.rotation.y = yaw
		cam_pivot.rotation.x = pitch

	if event.is_action_pressed("toggle_camera") and _gm:
		_gm.cycle_camera()
		_update_camera_mode()

	if event.is_action_pressed("pause") and _gm:
		_gm.toggle_pause()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _gm.paused else Input.MOUSE_MODE_CAPTURED

	if event.is_action_pressed("attack"):
		_try_attack()

	if event.is_action_pressed("interact"):
		_try_interact()

func _physics_process(delta: float) -> void:
	if _gm and _gm.paused:
		return

	if _attack_cd > 0.0:
		_attack_cd -= delta

	if not is_on_floor():
		velocity.y -= 14.0 * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (Transform3D(Basis.from_euler(Vector3(0, yaw, 0)), Vector3.ZERO) * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var sprinting := Input.is_action_pressed("sprint") and stamina > 5.0 and direction.length() > 0.1
	var speed := SPEED * (SPRINT_MULT if sprinting else 1.0)

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		bob = sin(Time.get_ticks_msec() * 0.012) * 0.06
		if sprinting:
			stamina = maxf(0.0, stamina - 18.0 * delta)
		else:
			stamina = minf(max_stamina, stamina + 12.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		bob = lerpf(bob, 0.0, 8.0 * delta)
		stamina = minf(max_stamina, stamina + 20.0 * delta)

	move_and_slide()

	if hurt_flash > 0.0:
		hurt_flash = maxf(0.0, hurt_flash - delta * 2.5)

	_update_camera_mode()

func _update_camera_mode() -> void:
	if not _gm or not camera:
		return
	match _gm.cam_mode:
		0:
			camera.position = Vector3(0, 1.55 + bob, 0)
			mesh.visible = false
		1:
			camera.position = Vector3(0, 1.8, 4.5)
			mesh.visible = true
		2:
			camera.position = Vector3(0, 1.5, -3.6)
			mesh.visible = true

func _try_attack() -> void:
	if _attack_cd > 0.0:
		return
	_attack_cd = 0.45
	var origin := global_position + Vector3(0, 1.0, 0)
	var facing := Vector3(-sin(yaw), 0, -cos(yaw)).normalized()
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = ATTACK_RANGE
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, origin + facing * 1.0)
	query.collision_mask = 4  # enemies layer
	var hits := space.intersect_shape(query, 8)
	for hit in hits:
		var col = hit.get("collider")
		if col and col.has_method("take_damage"):
			col.take_damage(ATTACK_DAMAGE)

func _try_interact() -> void:
	# برای کوئست talk / discover
	if _gm and _gm.quests:
		_gm.quests.report("talk")
		_gm.quests.report("discover")

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	hurt_flash = 0.7
	if _gm:
		_gm.player_damaged.emit(amount)
	if hp <= 0 and _gm:
		_gm.player_died.emit()

func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)
