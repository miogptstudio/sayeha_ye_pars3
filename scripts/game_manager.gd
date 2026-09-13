extends Node
## مدیر اصلی بازی — روز/شب، کوئست، دشمن، ذخیره

signal day_changed(day_fraction: float)
signal weather_changed(state: String, intensity: float)
signal quest_updated(quest_id: String, title: String, desc: String, progress: int, target: int)
signal player_damaged(amount: int)
signal player_died
signal enemy_killed(kind: int)

enum CamMode { FIRST, THIRD, SECOND }

var day_time: float = 8.0
var day_length_seconds: float = 720.0
var weather_state: String = "clear"
var weather_intensity: float = 0.0
var cam_mode: CamMode = CamMode.FIRST
var paused: bool = false
var look_sens: float = 1.0

var player: Node3D = null
var gold: int = 0
var xp: int = 0
var level: int = 1

var quests: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# سیستم کوئست
	quests = Node.new()
	quests.set_script(load("res://scripts/quest_system.gd"))
	quests.name = "QuestSystem"
	add_child(quests)
	if quests.has_signal("quest_changed"):
		quests.quest_changed.connect(_on_quest_changed)
	if quests.has_signal("quest_completed"):
		quests.quest_completed.connect(_on_quest_completed)

func _process(delta: float) -> void:
	if paused:
		return
	day_time += (24.0 / day_length_seconds) * delta
	if day_time >= 24.0:
		day_time -= 24.0
	day_changed.emit(day_fraction())

func day_fraction() -> float:
	return day_time / 24.0

func is_night() -> bool:
	return day_time < 5.5 or day_time > 19.5

func sun_height() -> float:
	return sin(day_fraction() * TAU)

func set_weather(state: String, intensity: float = 0.6) -> void:
	weather_state = state
	weather_intensity = clampf(intensity, 0.0, 1.0)
	weather_changed.emit(weather_state, weather_intensity)

func cycle_camera() -> void:
	match cam_mode:
		CamMode.FIRST:
			cam_mode = CamMode.THIRD
		CamMode.THIRD:
			cam_mode = CamMode.SECOND
		_:
			cam_mode = CamMode.FIRST

func toggle_pause() -> void:
	paused = not paused
	get_tree().paused = paused

func on_enemy_killed(kind: int) -> void:
	enemy_killed.emit(kind)
	# پاداش طلا
	var g := 5
	match kind:
		0: g = 5
		1: g = 25
		2: g = 120
	gold += g
	# پیشرفت کوئست
	if quests:
		if kind == 0:
			quests.report("kill_enemy")
		elif kind == 1:
			quests.report("kill_elite")
		elif kind == 2:
			quests.report("kill_boss")

func _on_quest_changed(qid: String, title: String, desc: String, prog: int, target: int) -> void:
	quest_updated.emit(qid, title, desc, prog, target)

func _on_quest_completed(_qid: String, reward_gold: int, reward_xp: int) -> void:
	gold += reward_gold
	xp += reward_xp
	while xp >= level * 100:
		xp -= level * 100
		level += 1
