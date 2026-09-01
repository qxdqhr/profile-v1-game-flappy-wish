extends Node
## Persists best scores per difficulty.

const SAVE_PATH := "user://flappy_wish_save.json"

var best := {"easy": 0, "medium": 0, "hard": 0}

func _ready() -> void:
	load_save()

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	for k in best.keys():
		best[k] = int(data.get(k, 0))

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(best))

func record(diff_id: String, score: int) -> Dictionary:
	var prev := int(best.get(diff_id, 0))
	var is_new := score > prev
	if is_new:
		best[diff_id] = score
		save()
	return {"best": maxi(score, prev), "is_new": is_new}
