extends Control

@onready var _title: Label = $VBox/Title
@onready var _best_all: Label = $VBox/BestAll
@onready var _play: Button = $VBox/Play
@onready var _diff_row: HBoxContainer = $VBox/DiffBtns
@onready var _note: Label = $VBox/Note

var _diff_btns: Dictionary = {}

func _ready() -> void:
	_title.text = "予愿飞翔"
	_note.text = "抽象几何版 · 玩法对齐原版"
	_play.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/play.tscn")
	)
	for id in GameConfig.DIFF_ORDER:
		var d: Dictionary = GameConfig.DIFFICULTIES[id]
		var b := Button.new()
		b.text = str(d["label"])
		b.custom_minimum_size = Vector2(84, 40)
		var diff_id := id
		b.pressed.connect(func() -> void:
			GameConfig.set_diff(diff_id)
			_refresh()
		)
		_diff_row.add_child(b)
		_diff_btns[id] = b
	if not GameConfig.difficulty_changed.is_connected(_on_diff):
		GameConfig.difficulty_changed.connect(_on_diff)
	_refresh()

func _on_diff(_id: String) -> void:
	_refresh()

func _refresh() -> void:
	_best_all.text = "最高  简单 %d  ·  中等 %d  ·  困难 %d" % [
		int(SaveData.best.get("easy", 0)),
		int(SaveData.best.get("medium", 0)),
		int(SaveData.best.get("hard", 0)),
	]
	_play.text = "开始飞翔 · %s" % str(GameConfig.get_diff()["label"])
	for id in _diff_btns.keys():
		var b: Button = _diff_btns[id] as Button
		var d: Dictionary = GameConfig.DIFFICULTIES[id]
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		if id == GameConfig.current_id:
			style.bg_color = d["color"]
			b.add_theme_color_override("font_color", Color.WHITE)
		else:
			style.bg_color = Color(0.2, 0.28, 0.4)
			b.add_theme_color_override("font_color", Color(0.85, 0.9, 1))
		b.add_theme_stylebox_override("normal", style)
		b.add_theme_stylebox_override("hover", style)
