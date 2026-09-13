extends Control
## اتصال HUD به GameManager و بازیکن

@onready var hp_bar: ProgressBar = $HPBar
@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var time_label: Label = $TimeLabel
@onready var gold_label: Label = $GoldLabel
@onready var quest_title: Label = $QuestPanel/QuestVBox/QuestTitle
@onready var quest_desc: Label = $QuestPanel/QuestVBox/QuestDesc
@onready var quest_progress: Label = $QuestPanel/QuestVBox/QuestProgress

var _gm: Node

func _ready() -> void:
	_gm = get_node_or_null("/root/GameManager")
	if _gm:
		if _gm.has_signal("quest_updated"):
			_gm.quest_updated.connect(_on_quest)
		if _gm.has_signal("day_changed"):
			_gm.day_changed.connect(_on_day)

func _process(_delta: float) -> void:
	if not _gm or not _gm.player:
		return
	var p = _gm.player
	if hp_bar and p.get("hp") != null:
		hp_bar.max_value = p.max_hp
		hp_bar.value = p.hp
	if stamina_bar and p.get("stamina") != null:
		stamina_bar.max_value = p.max_stamina
		stamina_bar.value = p.stamina
	if gold_label:
		gold_label.text = "طلا: %d | سطح: %d" % [_gm.gold, _gm.level]

func _on_day(frac: float) -> void:
	if not time_label or not _gm:
		return
	var h := int(_gm.day_time)
	var m := int((_gm.day_time - h) * 60.0)
	var period := "شب" if _gm.is_night() else "روز"
	time_label.text = "%s — %02d:%02d" % [period, h, m]

func _on_quest(_id: String, title: String, desc: String, prog: int, target: int) -> void:
	if quest_title:
		quest_title.text = "کوئست: " + title
	if quest_desc:
		quest_desc.text = desc
	if quest_progress:
		quest_progress.text = "پیشرفت: %d / %d" % [prog, target]
