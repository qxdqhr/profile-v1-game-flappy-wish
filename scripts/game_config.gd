extends Node
## Difficulty presets aligned with Phaser original (design units → px/s feel).

signal difficulty_changed(id: String)

var current_id: String = "medium"

## Original was per-frame @60fps on 375×667; values below are Godot px/s equivalents
## tuned so flap peak time ≈0.31s and pipe spacing feel matches.
var DIFFICULTIES := {
	"easy": {
		"label": "简单",
		"hint": "缝更大 · 更慢",
		"color": Color(0.24, 0.72, 0.47),
		"gravity": 980.0,
		"flap_impulse": -360.0,
		"max_fall": 520.0,
		"pipe_gap": 226.0,
		"pipe_speed": 168.0,
		"spawn_distance": 259.0,
		"hitbox_scale": 0.55,
		"bg_scroll": 28.0,
		"ground_scroll": 168.0,
		"bird_size": 56.0,
	},
	"medium": {
		"label": "中等",
		"hint": "均衡节奏",
		"color": Color(1.0, 0.42, 0.29),
		"gravity": 1100.0,
		"flap_impulse": -390.0,
		"max_fall": 560.0,
		"pipe_gap": 184.0,
		"pipe_speed": 210.0,
		"spawn_distance": 227.0,
		"hitbox_scale": 0.64,
		"bg_scroll": 35.0,
		"ground_scroll": 210.0,
		"bird_size": 56.0,
	},
	"hard": {
		"label": "困难",
		"hint": "窄缝高速",
		"color": Color(0.77, 0.27, 0.41),
		"gravity": 1240.0,
		"flap_impulse": -410.0,
		"max_fall": 600.0,
		"pipe_gap": 151.0,
		"pipe_speed": 245.0,
		"spawn_distance": 205.0,
		"hitbox_scale": 0.72,
		"bg_scroll": 40.0,
		"ground_scroll": 245.0,
		"bird_size": 56.0,
	},
}

const DIFF_ORDER := ["easy", "medium", "hard"]
const PIPE_SCORE := 1
const COIN_SCORE := 3

func get_diff() -> Dictionary:
	return DIFFICULTIES[current_id]

func set_diff(id: String) -> void:
	if not DIFFICULTIES.has(id):
		return
	current_id = id
	difficulty_changed.emit(id)

func cycle_diff(delta: int) -> void:
	var i := DIFF_ORDER.find(current_id)
	if i < 0:
		i = 1
	i = (i + delta + DIFF_ORDER.size()) % DIFF_ORDER.size()
	set_diff(DIFF_ORDER[i])
