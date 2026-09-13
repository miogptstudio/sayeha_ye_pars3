extends Node
## سیستم کوئست ساده — چند فصل ابتدایی سرزمین پارس

signal quest_changed(quest_id: String, title: String, desc: String, progress: int, target: int)
signal quest_completed(quest_id: String, reward_gold: int, reward_xp: int)

const QUESTS := {
	"prologue": {
		"title": "آغاز سفر",
		"desc": "با کدخدا صحبت کن و مسیر را بیاموز.",
		"target": 1,
		"type": "talk",
		"next": "gather",
		"gold": 10,
		"xp": 50,
	},
	"gather": {
		"title": "جمع‌آوری چوب",
		"desc": "۵ واحد چوب از درختان اطراف جمع کن.",
		"target": 5,
		"type": "gather_wood",
		"next": "hunt",
		"gold": 25,
		"xp": 80,
	},
	"hunt": {
		"title": "شکار دشمنان",
		"desc": "۳ دشمن را شکست بده.",
		"target": 3,
		"type": "kill_enemy",
		"next": "elite",
		"gold": 50,
		"xp": 120,
	},
	"elite": {
		"title": "نخبه‌کشی",
		"desc": "یک دشمن نخبه (Elite) را از پا درآور.",
		"target": 1,
		"type": "kill_elite",
		"next": "temple",
		"gold": 100,
		"xp": 200,
	},
	"temple": {
		"title": "معبد خورشید",
		"desc": "به معبد خورشید برس و اکتشاف کن.",
		"target": 1,
		"type": "discover",
		"next": "boss",
		"gold": 150,
		"xp": 300,
	},
	"boss": {
		"title": "سایهٔ بزرگ",
		"desc": "با رئیس نهایی مبارزه کن.",
		"target": 1,
		"type": "kill_boss",
		"next": "",
		"gold": 500,
		"xp": 800,
	},
}

var current_id: String = "prologue"
var progress: int = 0
var completed: Array[String] = []

func _ready() -> void:
	# اتصال به GameManager در صورت وجود
	call_deferred("_emit_current")

func _emit_current() -> void:
	var q: Dictionary = QUESTS.get(current_id, {})
	if q.is_empty():
		return
	quest_changed.emit(current_id, q["title"], q["desc"], progress, q["target"])

func get_current() -> Dictionary:
	return QUESTS.get(current_id, {})

func report(event_type: String, amount: int = 1) -> void:
	var q: Dictionary = QUESTS.get(current_id, {})
	if q.is_empty():
		return
	if q["type"] != event_type:
		return
	progress = mini(progress + amount, q["target"])
	quest_changed.emit(current_id, q["title"], q["desc"], progress, q["target"])
	if progress >= q["target"]:
		_complete()

func _complete() -> void:
	var q: Dictionary = QUESTS.get(current_id, {})
	if q.is_empty():
		return
	completed.append(current_id)
	quest_completed.emit(current_id, q["gold"], q["xp"])
	var next_id: String = q.get("next", "")
	if next_id != "" and QUESTS.has(next_id):
		current_id = next_id
		progress = 0
		_emit_current()
	else:
		current_id = ""
		progress = 0
